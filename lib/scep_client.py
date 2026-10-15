#!/usr/bin/env python3
"""
scep_client.py - minimal SCEP (RFC 8894) test client for syscheck.

Dependencies: python3 standard library (3.6+) and the openssl CLI.
No pip packages, no sscep.

What it does:
  1. GetCACaps     - plain HTTP GET, lists server capabilities
  2. GetCACert     - plain HTTP GET, CA cert or CA+RA bundle (PKCS#7)
  3. PKCSReq       - builds the SCEP PKIMessage itself:
                       - CSR with challengePassword    (openssl req)
                       - pkcsPKIEnvelope to RA/CA cert (openssl cms -encrypt)
                       - SignedData + SCEP attributes  (built here in DER,
                         signature via openssl dgst -sign)
  4. CertPoll      - if the server answers PENDING, polls until issued
  5. Response      - checks signature, transactionID and nonces,
                     decrypts the certificate (openssl cms -decrypt)

Renewal: pass --sign-cert/--sign-key with an existing certificate and the
request is signed with that instead of a throwaway self-signed one.

Output: KEY=VALUE lines on stdout (for the syscheck wrapper), debug on
stderr with -v.

Exit codes:
  0 certificate issued
  1 local error (bad arguments, openssl failure)
  2 transport error (HTTP/TLS/connection, GetCACaps/GetCACert failed)
  3 server answered FAILURE (see FAILINFO)
  4 still PENDING after max polls
  5 invalid response (parse, signature, transactionID or nonce mismatch)
"""

import argparse
import base64
import binascii
import hashlib
import os
import re
import shutil
import ssl
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

VERBOSE = False

EXIT_OK, EXIT_LOCAL, EXIT_TRANSPORT, EXIT_FAILURE, EXIT_PENDING, EXIT_BADRESP = range(6)


class ScepError(Exception):
    def __init__(self, code, msg):
        Exception.__init__(self, msg)
        self.code = code
        self.msg = msg


def dbg(msg):
    if VERBOSE:
        sys.stderr.write("[scep] %s\n" % msg)


def out(key, value):
    value = str(value).replace("\n", " ").strip()
    sys.stdout.write("%s=%s\n" % (key, value))
    sys.stdout.flush()


# --------------------------------------------------------------------------
# Minimal DER encoder / decoder (only what SCEP needs)
# --------------------------------------------------------------------------

def der_len(n):
    if n < 0x80:
        return bytes([n])
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return bytes([0x80 | len(b)]) + b


def der(tag, content):
    return bytes([tag]) + der_len(len(content)) + content


def der_seq(*items):
    return der(0x30, b"".join(items))


def der_set(*items, sort=False):
    items = list(items)
    if sort:  # DER SET OF ordering: sort by encoding
        items.sort()
    return der(0x31, b"".join(items))


def der_int(n):
    if n == 0:
        return der(0x02, b"\x00")
    b = n.to_bytes((n.bit_length() + 8) // 8, "big")  # +8 keeps sign bit clear
    return der(0x02, b)


def der_int_raw(content):
    """INTEGER from already-encoded content bytes (e.g. a cert serial)."""
    return der(0x02, content)


def der_null():
    return b"\x05\x00"


def der_octets(b):
    return der(0x04, b)


def der_printable(s):
    return der(0x13, s.encode("ascii"))


def der_oid(dotted):
    parts = [int(p) for p in dotted.split(".")]
    body = bytes([40 * parts[0] + parts[1]])
    for p in parts[2:]:
        chunk = [p & 0x7F]
        p >>= 7
        while p:
            chunk.insert(0, 0x80 | (p & 0x7F))
            p >>= 7
        body += bytes(chunk)
    return der(0x06, body)


def der_explicit(n, content):
    return der(0xA0 + n, content)


def der_parse(data, pos=0):
    """Return (tag, content_start, content_end, next_pos)."""
    tag = data[pos]
    pos += 1
    ln = data[pos]
    pos += 1
    if ln & 0x80:
        nb = ln & 0x7F
        if nb == 0:
            raise ValueError("indefinite length not supported")
        ln = int.from_bytes(data[pos:pos + nb], "big")
        pos += nb
    end = pos + ln
    if end > len(data):
        raise ValueError("DER length runs past end of data")
    return tag, pos, end, end


def der_children(data, start, end):
    """List of (tag, cstart, cend, full_start, full_end) for a constructed value."""
    res = []
    pos = start
    while pos < end:
        tag, cs, ce, nxt = der_parse(data, pos)
        res.append((tag, cs, ce, pos, nxt))
        pos = nxt
    return res


def oid_to_str(body):
    vals = []
    v = 0
    for b in body:
        v = (v << 7) | (b & 0x7F)
        if not b & 0x80:
            vals.append(v)
            v = 0
    first = vals[0]
    head = [min(first // 40, 2), first - 40 * min(first // 40, 2)]
    return ".".join(str(x) for x in head + vals[1:])


# --------------------------------------------------------------------------
# OIDs
# --------------------------------------------------------------------------

OID_DATA = "1.2.840.113549.1.7.1"
OID_SIGNED_DATA = "1.2.840.113549.1.7.2"
OID_RSA = "1.2.840.113549.1.1.1"
OID_CONTENT_TYPE = "1.2.840.113549.1.9.3"
OID_MESSAGE_DIGEST = "1.2.840.113549.1.9.4"
OID_SIGNING_TIME = "1.2.840.113549.1.9.5"

SCEP = "2.16.840.1.113733.1.9."
OID_MESSAGE_TYPE = SCEP + "2"
OID_PKI_STATUS = SCEP + "3"
OID_FAIL_INFO = SCEP + "4"
OID_SENDER_NONCE = SCEP + "5"
OID_RECIPIENT_NONCE = SCEP + "6"
OID_TRANS_ID = SCEP + "7"

DIGESTS = {
    "sha1": ("1.3.14.3.2.26", "sha1"),
    "sha256": ("2.16.840.1.101.3.4.2.1", "sha256"),
    "sha512": ("2.16.840.1.101.3.4.2.3", "sha512"),
}

CIPHERS = {
    "aes128": "-aes-128-cbc",
    "aes256": "-aes-256-cbc",
    "des3": "-des-ede3-cbc",
}

LEGACY = ["-provider", "legacy", "-provider", "default"]  # OpenSSL 3 only

MSG_PKCSREQ = "19"
MSG_CERTPOLL = "20"
MSG_CERTREP = "3"

STATUS_NAMES = {"0": "SUCCESS", "2": "FAILURE", "3": "PENDING"}
FAILINFO_NAMES = {"0": "badAlg", "1": "badMessageCheck", "2": "badRequest",
                  "3": "badTime", "4": "badCertId"}


# --------------------------------------------------------------------------
# openssl helpers
# --------------------------------------------------------------------------

class Openssl(object):
    def __init__(self, binary, workdir):
        self.bin = binary
        self.dir = workdir

    def path(self, name):
        return os.path.join(self.dir, name)

    def run(self, args, stdin=None, check=True):
        cmd = [self.bin] + args
        dbg("openssl " + " ".join(args))
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, cwd=self.dir)
        so, se = p.communicate(stdin)
        if check and p.returncode != 0:
            raise ScepError(EXIT_LOCAL, "openssl %s failed: %s" %
                            (args[0], se.decode(errors="replace").strip()[:400]))
        return p.returncode, so, se

    def write(self, name, data):
        p = self.path(name)
        with open(p, "wb") as f:
            f.write(data)
        return p

    def read(self, name):
        with open(self.path(name), "rb") as f:
            return f.read()


def cnf_escape(v):
    """Escape a value for an openssl config file ($ expands variables)."""
    return v.replace("\\", "\\\\").replace("$", "\\$").replace("#", "\\#")


def split_pem(text):
    return re.findall(r"-----BEGIN CERTIFICATE-----.+?-----END CERTIFICATE-----",
                      text, re.S)


def cert_fields(cert_der):
    """Extract issuer (DER), serial (content bytes), subject (DER), spki (DER)."""
    _, cs, ce, _ = der_parse(cert_der, 0)              # Certificate
    tbs = der_children(cert_der, cs, ce)[0]
    kids = der_children(cert_der, tbs[1], tbs[2])
    i = 1 if kids[0][0] == 0xA0 else 0                # optional [0] version
    serial = cert_der[kids[i][1]:kids[i][2]]
    issuer = cert_der[kids[i + 2][3]:kids[i + 2][4]]
    subject = cert_der[kids[i + 4][3]:kids[i + 4][4]]
    spki = cert_der[kids[i + 5][3]:kids[i + 5][4]]
    return {"serial": serial, "issuer": issuer, "subject": subject, "spki": spki}


# --------------------------------------------------------------------------
# HTTP
# --------------------------------------------------------------------------

class Http(object):
    def __init__(self, url, timeout, cafile, insecure):
        self.url = url
        self.timeout = timeout
        self.ctx = None
        if url.lower().startswith("https"):
            if insecure:
                self.ctx = ssl._create_unverified_context()
            else:
                self.ctx = ssl.create_default_context(cafile=cafile)

    def request(self, operation, message=None, post_body=None):
        q = {"operation": operation}
        if message is not None:
            q["message"] = message
        sep = "&" if "?" in self.url else "?"
        url = self.url + sep + urllib.parse.urlencode(q)
        headers = {"User-Agent": "syscheck-scep/1.0"}
        data = None
        if post_body is not None:
            data = post_body
            headers["Content-Type"] = "application/x-pki-message"
        dbg("%s %s (%s bytes)" % ("POST" if data else "GET", url[:160],
                                   len(data) if data else 0))
        req = urllib.request.Request(url, data=data, headers=headers)
        try:
            resp = urllib.request.urlopen(req, timeout=self.timeout, context=self.ctx)
            body = resp.read()
            ctype = resp.headers.get("Content-Type", "")
            dbg("-> HTTP %s %s (%d bytes)" % (resp.status, ctype, len(body)))
            return resp.status, ctype, body
        except urllib.error.HTTPError as e:
            body = e.read()[:300].decode(errors="replace").replace("\n", " ")
            raise ScepError(EXIT_TRANSPORT, "%s: HTTP %s %s %s" %
                            (operation, e.code, e.reason, body))
        except Exception as e:  # URLError, socket timeout, TLS errors
            raise ScepError(EXIT_TRANSPORT, "%s: %s" % (operation, e))


# --------------------------------------------------------------------------
# SCEP client
# --------------------------------------------------------------------------

class ScepClient(object):
    def __init__(self, args, ossl):
        self.a = args
        self.o = ossl
        self.http = Http(args.url, args.timeout, args.tls_cafile, args.insecure)
        self.caps = []
        self.ca_certs_pem = []      # every cert from GetCACert
        self.enc_cert = None         # cert we encrypt the request to (RA or CA)
        self.issuer_name = None      # DER Name of the issuing CA (for CertPoll)

    # ---- step 1 -------------------------------------------------------
    def get_ca_caps(self):
        status, ctype, body = self.http.request("GetCACaps")
        caps = body.decode(errors="replace").split()
        self.caps = [c.strip() for c in caps if c.strip()]
        return self.caps

    def cap(self, name):
        return name.lower() in [c.lower() for c in self.caps]

    # ---- step 2 -------------------------------------------------------
    def get_ca_cert(self):
        status, ctype, body = self.http.request("GetCACert", message=self.a.ca_ident)
        if not body:
            raise ScepError(EXIT_TRANSPORT, "GetCACert: empty response")
        ctype = ctype.lower()
        if "x-x509-ca-ra-cert" in ctype or body[:1] == b"\x30" and b"\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x07\x02" in body[:40]:
            self.o.write("getcacert.p7b", body)
            _, so, _ = self.o.run(["pkcs7", "-inform", "DER", "-in", "getcacert.p7b", "-print_certs"])
            pems = split_pem(so.decode())
        else:
            self.o.write("getcacert.der", body)
            _, so, _ = self.o.run(["x509", "-inform", "DER", "-in", "getcacert.der"])
            pems = split_pem(so.decode())
        if not pems:
            raise ScepError(EXIT_BADRESP, "GetCACert: no certificates in response (%s)" % ctype)
        self.ca_certs_pem = pems
        self.o.write("ca-all.pem", ("\n".join(pems) + "\n").encode())

        info = []
        for n, pem in enumerate(pems):
            name = "cacert-%d.pem" % n
            self.o.write(name, pem.encode() + b"\n")
            _, txt, _ = self.o.run(["x509", "-in", name, "-noout", "-text"])
            txt = txt.decode(errors="replace")
            _, d, _ = self.o.run(["x509", "-in", name, "-outform", "DER"])
            info.append({
                "file": name,
                "der": d,
                "is_ca": "CA:TRUE" in txt,
                "keyenc": "Key Encipherment" in txt,
                "fields": cert_fields(d),
            })

        # pick encryption cert: RA with keyEncipherment > any RA > the CA
        ras = [c for c in info if not c["is_ca"]]
        cas = [c for c in info if c["is_ca"]]
        enc = ([c for c in ras if c["keyenc"]] or ras or cas or info)[0]
        self.enc_cert = enc["file"]
        if ras:
            self.issuer_name = enc["fields"]["issuer"]
        else:
            self.issuer_name = enc["fields"]["subject"]
        return info, ras, cas

    # ---- key, CSR, signer ----------------------------------------------
    def make_key_and_csr(self):
        o = self.o
        o.run(["genpkey", "-algorithm", "RSA", "-pkeyopt",
               "rsa_keygen_bits:%d" % self.a.keysize, "-out", "client.key"])
        # NB: openssl req silently drops the [attrs] section (challengePassword)
        # when -subj is used, so the subject goes into the config file instead.
        cfg = ["[req]", "prompt = no", "distinguished_name = dn"]
        if self.a.challenge:
            cfg.append("attributes = attrs")
        cfg.append("[dn]")
        rdns = [r for r in re.split(r"(?<!\\)/", self.a.subject) if r]
        if not rdns:
            raise ScepError(EXIT_LOCAL, "empty subject %r" % self.a.subject)
        for n, rdn in enumerate(rdns):
            if "=" not in rdn:
                raise ScepError(EXIT_LOCAL, "bad subject component %r (use /CN=x/O=y)" % rdn)
            k, v = rdn.split("=", 1)
            cfg.append("%d.%s = %s" % (n, k.strip(), cnf_escape(v.replace("\\/", "/"))))
        if self.a.challenge:
            cfg += ["[attrs]", "challengePassword = %s" % cnf_escape(self.a.challenge)]
        o.write("req.cnf", ("\n".join(cfg) + "\n").encode())
        cmd = ["req", "-new", "-config", "req.cnf", "-key", "client.key",
               "-out", "client.csr"]
        for san in self.a.san or []:
            cmd += ["-addext", "subjectAltName=%s" % san]
        o.run(cmd)
        if self.a.challenge:
            _, txt, _ = o.run(["req", "-in", "client.csr", "-noout", "-text"])
            if b"challengePassword" not in txt:
                raise ScepError(EXIT_LOCAL, "challengePassword missing from generated CSR")
        o.run(["req", "-in", "client.csr", "-outform", "DER", "-out", "client.csr.der"])

    def make_signer(self):
        """Self-signed cert for signing the request (or existing cert for renewal)."""
        o = self.o
        if self.a.sign_cert:
            shutil.copy(self.a.sign_cert, o.path("signer.pem"))
            shutil.copy(self.a.sign_key, o.path("signer.key"))
        else:
            shutil.copy(o.path("client.key"), o.path("signer.key"))
            o.run(["req", "-x509", "-new", "-key", "signer.key", "-subj", self.a.subject,
                   "-days", "1", "-config", "req.cnf", "-out", "signer.pem"])
        _, d, _ = o.run(["x509", "-in", "signer.pem", "-outform", "DER"])
        self.signer_der = d
        self.signer_fields = cert_fields(d)
        _, pub, _ = o.run(["pkey", "-in", "client.key", "-pubout", "-outform", "DER"])
        self.trans_id = hashlib.sha256(pub).hexdigest().upper()
        # subject name of the request (for CertPoll IssuerAndSubject)
        _, csr_txt, _ = o.run(["req", "-in", "client.csr", "-noout", "-subject",
                               "-nameopt", "RFC2253"])
        self.csr_subject_txt = csr_txt.decode().split("=", 1)[-1].strip()

    # ---- build PKIMessage ---------------------------------------------
    def envelope(self, payload_der):
        o = self.o
        o.write("payload.der", payload_der)
        o.run(["cms", "-encrypt", "-binary", "-in", "payload.der", "-outform", "DER",
               "-out", "envelope.der", CIPHERS[self.cipher], self.enc_cert])
        return o.read("envelope.der")

    def signed_pkimessage(self, msg_type, envelope_der, nonce):
        dig_oid, dig_name = DIGESTS[self.digest]
        msg_digest = hashlib.new(dig_name, envelope_der).digest()
        attrs = [
            der_seq(der_oid(OID_CONTENT_TYPE), der_set(der_oid(OID_DATA))),
            der_seq(der_oid(OID_MESSAGE_DIGEST), der_set(der_octets(msg_digest))),
            der_seq(der_oid(OID_SIGNING_TIME), der_set(der(0x17, time.strftime(
                "%y%m%d%H%M%SZ", time.gmtime()).encode()))),
            der_seq(der_oid(OID_MESSAGE_TYPE), der_set(der_printable(msg_type))),
            der_seq(der_oid(OID_TRANS_ID), der_set(der_printable(self.trans_id))),
            der_seq(der_oid(OID_SENDER_NONCE), der_set(der_octets(nonce))),
        ]
        attrs_set = der_set(*attrs, sort=True)           # what gets signed
        self.o.write("attrs.der", attrs_set)
        _, sig, _ = self.o.run(["dgst", "-" + dig_name, "-sign", "signer.key",
                                "-binary", "attrs.der"])
        signed_attrs = b"\xa0" + attrs_set[1:]           # [0] IMPLICIT
        alg = der_seq(der_oid(dig_oid), der_null())
        f = self.signer_fields
        signer_info = der_seq(
            der_int(1),
            der_seq(f["issuer"], der_int_raw(f["serial"])),
            alg,
            signed_attrs,
            der_seq(der_oid(OID_RSA), der_null()),
            der_octets(sig),
        )
        signed_data = der_seq(
            der_int(1),
            der_set(alg),
            der_seq(der_oid(OID_DATA), der_explicit(0, der_octets(envelope_der))),
            b"\xa0" + der_set(self.signer_der)[1:],        # [0] IMPLICIT certificates
            der_set(signer_info),
        )
        return der_seq(der_oid(OID_SIGNED_DATA), der_explicit(0, signed_data))

    def send_pkimessage(self, msg):
        if self.cap("POSTPKIOperation") and not self.a.force_get:
            return self.http.request("PKIOperation", post_body=msg)
        return self.http.request("PKIOperation",
                                 message=base64.b64encode(msg).decode())

    # ---- parse CertRep -------------------------------------------------
    def parse_certrep(self, body, nonce):
        o = self.o
        o.write("response.der", body)
        try:
            _, cs, ce, _ = der_parse(body, 0)
            kids = der_children(body, cs, ce)
            if oid_to_str(body[kids[0][1]:kids[0][2]]) != OID_SIGNED_DATA:
                raise ValueError("not SignedData")
            sd = der_children(body, kids[1][1], kids[1][2])[0]
            sd_kids = der_children(body, sd[1], sd[2])
            signer_infos = sd_kids[-1]
            si = der_children(body, signer_infos[1], signer_infos[2])[0]
            si_kids = der_children(body, si[1], si[2])
            sattrs = [k for k in si_kids if k[0] == 0xA0][0]
            attrs = {}
            for a in der_children(body, sattrs[1], sattrs[2]):
                ak = der_children(body, a[1], a[2])
                oid = oid_to_str(body[ak[0][1]:ak[0][2]])
                vals = der_children(body, ak[1][1], ak[1][2])
                attrs[oid] = body[vals[0][1]:vals[0][2]]
        except Exception as e:
            raise ScepError(EXIT_BADRESP, "cannot parse CertRep (%s), content-type/size "
                            "suggests this is not a SCEP response" % e)

        # signature check: first full chain, then signature only
        base = ["cms", "-verify", "-binary", "-inform", "DER", "-in", "response.der",
                "-certfile", "ca-all.pem", "-out", "inner.der"]
        rc, _, se = o.run(base + ["-CAfile", "ca-all.pem", "-purpose", "any"], check=False)
        chain = "ok"
        if rc != 0:
            chain = "failed"
            dbg("chain verify failed: %s" % se.decode(errors="replace").strip()[:300])
            rc, _, se = o.run(base + ["-noverify"], check=False)
            if rc != 0:
                raise ScepError(EXIT_BADRESP, "CertRep signature invalid: %s" %
                                se.decode(errors="replace").strip()[:300])
        self.chain_verify = chain

        mtype = attrs.get(OID_MESSAGE_TYPE, b"").decode(errors="replace")
        status = attrs.get(OID_PKI_STATUS, b"").decode(errors="replace")
        tid = attrs.get(OID_TRANS_ID, b"").decode(errors="replace")
        rnonce = attrs.get(OID_RECIPIENT_NONCE)
        if mtype != MSG_CERTREP:
            raise ScepError(EXIT_BADRESP, "unexpected messageType %r in response" % mtype)
        if tid != self.trans_id:
            raise ScepError(EXIT_BADRESP, "transactionID mismatch (sent %s, got %s)" %
                            (self.trans_id, tid))
        if rnonce != nonce:
            raise ScepError(EXIT_BADRESP, "recipientNonce does not match our senderNonce")
        fail = attrs.get(OID_FAIL_INFO, b"").decode(errors="replace")
        return status, fail

    def extract_cert(self):
        o = self.o
        # response is encrypted to the cert that signed the request; for renewal
        # some servers use the new key instead, so try both
        # If the server used single DES/RC2, OpenSSL 3 needs the legacy provider.
        tried = [("signer.pem", "signer.key", []), ("signer.pem", "client.key", []),
                 ("signer.pem", "signer.key", LEGACY), ("signer.pem", "client.key", LEGACY)]
        self.legacy_cipher = False
        for crt, key, extra in tried:
            rc, _, se = o.run(["cms", "-decrypt", "-binary", "-inform", "DER",
                               "-in", "inner.der", "-recip", crt, "-inkey", key,
                               "-out", "issued.p7b"] + extra, check=False)
            if rc == 0:
                self.legacy_cipher = bool(extra)
                break
        else:
            raise ScepError(EXIT_BADRESP, "cannot decrypt CertRep envelope: %s" %
                            se.decode(errors="replace").strip()[:300])
        _, so, _ = o.run(["pkcs7", "-inform", "DER", "-in", "issued.p7b", "-print_certs"])
        pems = split_pem(so.decode())
        _, mypub, _ = o.run(["pkey", "-in", "client.key", "-pubout"])
        for n, pem in enumerate(pems):
            o.write("issued-%d.pem" % n, pem.encode() + b"\n")
            _, pub, _ = o.run(["x509", "-in", "issued-%d.pem" % n, "-noout", "-pubkey"])
            if pub.strip() == mypub.strip():
                return "issued-%d.pem" % n
        raise ScepError(EXIT_BADRESP, "response contains %d cert(s) but none matches "
                        "our public key" % len(pems))

    # ---- enrollment ----------------------------------------------------
    def choose_algs(self):
        self.digest = self.a.digest
        self.cipher = self.a.cipher
        if self.a.digest == "auto":
            self.digest = "sha256" if (self.cap("SHA-256") or self.cap("SCEPStandard")) \
                else ("sha512" if self.cap("SHA-512") else "sha1")
        if self.a.cipher == "auto":
            self.cipher = "aes128" if (self.cap("AES") or self.cap("SCEPStandard")) else "des3"

    def enroll(self):
        self.make_key_and_csr()
        self.make_signer()
        self.choose_algs()
        out("DIGEST", self.digest)
        out("CIPHER", self.cipher)
        out("TRANSACTION_ID", self.trans_id)

        csr_der = self.o.read("client.csr.der")
        nonce = os.urandom(16)
        msg = self.signed_pkimessage(MSG_PKCSREQ, self.envelope(csr_der), nonce)
        _, _, body = self.send_pkimessage(msg)
        status, fail = self.parse_certrep(body, nonce)

        polls = 0
        while status == "3" and polls < self.a.max_polls:
            polls += 1
            dbg("PENDING, poll %d/%d in %ss" % (polls, self.a.max_polls, self.a.poll_interval))
            time.sleep(self.a.poll_interval)
            ias = der_seq(self.issuer_name, self.signer_fields["subject"]
                          if not self.a.sign_cert else self.csr_subject_der())
            nonce = os.urandom(16)
            msg = self.signed_pkimessage(MSG_CERTPOLL, self.envelope(ias), nonce)
            _, _, body = self.send_pkimessage(msg)
            status, fail = self.parse_certrep(body, nonce)
        out("POLLS", polls)
        out("CHAIN_VERIFY", self.chain_verify)
        out("STATUS", STATUS_NAMES.get(status, "UNKNOWN(%s)" % status))

        if status == "2":
            out("FAILINFO", FAILINFO_NAMES.get(fail, fail or "none"))
            raise ScepError(EXIT_FAILURE, "server rejected request: FAILURE failInfo=%s" %
                            FAILINFO_NAMES.get(fail, fail or "none"))
        if status == "3":
            raise ScepError(EXIT_PENDING, "still PENDING after %d polls" % polls)
        if status != "0":
            raise ScepError(EXIT_BADRESP, "unknown pkiStatus %r" % status)
        return self.extract_cert()

    def csr_subject_der(self):
        # subject of the new request (renewal: signer cert subject may differ)
        _, d, _ = self.o.run(["req", "-x509", "-new", "-key", "client.key", "-subj",
                              self.a.subject, "-days", "1", "-config", "req.cnf",
                              "-outform", "DER"])
        return cert_fields(d)["subject"]


# --------------------------------------------------------------------------

def main():
    global VERBOSE
    p = argparse.ArgumentParser(description="Minimal SCEP test client (python3 + openssl only)")
    p.add_argument("-u", "--url", required=True, help="SCEP URL, without ?operation=")
    p.add_argument("-p", "--challenge", default="", help="challengePassword (empty = none)")
    p.add_argument("-s", "--subject", default=None, help="subject, e.g. /CN=scep-test")
    p.add_argument("--san", action="append", help="subjectAltName, e.g. DNS:host.example (repeatable)")
    p.add_argument("-k", "--keysize", type=int, default=2048)
    p.add_argument("--digest", default="auto", choices=["auto"] + sorted(DIGESTS))
    p.add_argument("--cipher", default="auto", choices=["auto"] + sorted(CIPHERS))
    p.add_argument("--ca-ident", default="syscheck", help="message= value for GetCACert")
    p.add_argument("--sign-cert", help="existing cert to sign with (renewal)")
    p.add_argument("--sign-key", help="key for --sign-cert")
    p.add_argument("--max-polls", type=int, default=0, help="CertPoll attempts on PENDING")
    p.add_argument("--poll-interval", type=int, default=5)
    p.add_argument("--force-get", action="store_true", help="use GET even if POST is supported")
    p.add_argument("--timeout", type=int, default=30)
    p.add_argument("--tls-cafile", help="CA bundle for https SCEP URLs")
    p.add_argument("--insecure", action="store_true", help="skip TLS verification (https)")
    p.add_argument("--openssl", default=shutil.which("openssl") or "/usr/bin/openssl")
    p.add_argument("-o", "--outdir", help="copy key/cert/CA certs here (default: discard)")
    p.add_argument("--caps-only", action="store_true", help="only GetCACaps + GetCACert")
    p.add_argument("-v", "--verbose", action="store_true")
    a = p.parse_args()
    VERBOSE = a.verbose

    if not a.subject:
        a.subject = "/CN=syscheck-scep-%d" % int(time.time())
    if bool(a.sign_cert) != bool(a.sign_key):
        p.error("--sign-cert and --sign-key go together")

    workdir = tempfile.mkdtemp(prefix="scep-")
    o = Openssl(a.openssl, workdir)
    t0 = time.time()
    code = EXIT_OK
    try:
        c = ScepClient(a, o)
        caps = c.get_ca_caps()
        out("CAPS", ",".join(caps) or "(none)")
        info, ras, cas = c.get_ca_cert()
        out("CA_CERTS", len(info))
        out("RA_MODE", "yes" if ras else "no")
        _, enc_subj, _ = o.run(["x509", "-in", c.enc_cert, "-noout", "-subject",
                                "-nameopt", "RFC2253"])
        out("ENC_CERT", enc_subj.decode().split("=", 1)[-1].strip())
        if a.caps_only:
            out("MESSAGE", "GetCACaps/GetCACert OK")
        else:
            issued = c.enroll()
            _, txt, _ = o.run(["x509", "-in", issued, "-noout", "-subject", "-issuer",
                               "-serial", "-enddate", "-nameopt", "RFC2253"])
            fields = dict(l.split("=", 1) for l in txt.decode().splitlines() if "=" in l)
            out("CERT_SUBJECT", fields.get("subject", "").strip())
            out("CERT_ISSUER", fields.get("issuer", "").strip())
            out("CERT_SERIAL", fields.get("serial", "").strip())
            out("CERT_NOTAFTER", fields.get("notAfter", "").strip())
            out("RESP_LEGACY_CIPHER", "yes" if c.legacy_cipher else "no")
            out("MESSAGE", "certificate issued")
            if a.outdir:
                os.makedirs(a.outdir, exist_ok=True)
                shutil.copy(o.path(issued), os.path.join(a.outdir, "cert.pem"))
                shutil.copy(o.path("client.key"), os.path.join(a.outdir, "key.pem"))
                os.chmod(os.path.join(a.outdir, "key.pem"), 0o600)
                shutil.copy(o.path("ca-all.pem"), os.path.join(a.outdir, "ca.pem"))
    except ScepError as e:
        out("MESSAGE", e.msg)
        code = e.code
    except Exception as e:
        out("MESSAGE", "internal error: %s: %s" % (type(e).__name__, e))
        code = EXIT_LOCAL
    finally:
        out("TIME_MS", int((time.time() - t0) * 1000))
        if VERBOSE:
            dbg("workdir kept: %s" % workdir)
        else:
            shutil.rmtree(workdir, ignore_errors=True)
    out("EXIT", code)
    return code


if __name__ == "__main__":
    sys.exit(main())
