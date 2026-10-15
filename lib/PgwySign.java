import com.id2tech.security.pkcs7.SignedData;
import com.id2tech.security.pkcs7.SignedMessage;
import com.id2tech.security.util.DerEncode;
import com.id2tech.security.x509.Attribute;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.util.Base64;

/**
 * Signs a PGWY dataToSign blob by wrapping it in a PKCS#7 SignedData,
 * loading the officer key directly from a PKCS12 file — no PKCS11 involved.
 *
 * Usage:
 *   java -cp ".;cm-sdk.jar;cm-common.jar;common.jar;bcprov-jdk15on-1.70.jar" \
 *        PgwySign <p12file> <password> <base64_dataToSign> <outfile>
 *
 * The base64-encoded signed blob is printed to stdout.
 * Paste that value into the "signature" field in Postman.
 */
public class PgwySign {

    public static void main(String[] args) {
        try {
            if (args.length != 4) {
                System.err.println("Usage: PgwySign <p12file> <password> <base64_dataToSign> <outfile>");
                System.exit(1);
            }

            String p12file  = args[0];
            String password = args[1];
            String b64data  = args[2];
            String outfile  = args[3];

            // 1. Decode the dataToSign blob
            byte[] dataToSign = Base64.getDecoder().decode(b64data);

            // 2. Load the PKCS12 keystore directly — no SDK keystore machinery
            KeyStore ks = KeyStore.getInstance("PKCS12");
            try (FileInputStream fis = new FileInputStream(p12file)) {
                ks.load(fis, password.toCharArray());
            }

            // 3. Get the first key entry
            String alias = null;
            java.util.Enumeration<String> aliases = ks.aliases();
            while (aliases.hasMoreElements()) {
                String a = aliases.nextElement();
                if (ks.isKeyEntry(a)) {
                    alias = a;
                    break;
                }
            }
            if (alias == null) {
                throw new Exception("No key entry found in " + p12file);
            }

            PrivateKey privateKey = (PrivateKey) ks.getKey(alias, password.toCharArray());
            X509Certificate cert  = (X509Certificate) ks.getCertificate(alias);

            System.err.println("Using certificate: " + cert.getSubjectDN());

            // 4. Build SignedData from raw dataToSign bytes (false = content embedded, not detached)
            SignedData sd = new SignedData(dataToSign, false);

            // 5. Add certificate and signer
            //    addSigner(PrivateKey, X509Certificate, signedAttrs, unsignedAttrs, algorithmName)
            //    null attrs = use defaults, null algorithm = use cert's algorithm
            sd.addCertificate(cert);
            sd.addSigner(privateKey, cert, (Attribute[]) null, (Attribute[]) null, (String) null);

            // 6. Wrap in SignedMessage and encode to bytes via DerEncode
            SignedMessage sm = new SignedMessage(sd);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            DerEncode encoder = new DerEncode(baos);
            sm.encode(encoder);
            byte[] signed = baos.toByteArray();

            // 7. Write binary output and print base64
            Files.write(Paths.get(outfile), signed);
            String b64result = Base64.getEncoder().encodeToString(signed);
            System.out.println(b64result);

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}