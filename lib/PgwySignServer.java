import com.id2tech.security.pkcs7.SignedData;
import com.id2tech.security.pkcs7.SignedMessage;
import com.id2tech.security.util.DerEncode;
import com.id2tech.security.x509.Attribute;
import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.util.Base64;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Persistent PGWY signing service.
 *
 * Loads the officer P12 ONCE at startup, then listens on a local TCP port
 * and signs dataToSign blobs on demand - no JVM startup cost per request,
 * so it behaves like a real signing service instead of a one-shot CLI tool.
 *
 * Protocol (deliberately trivial - one line in, one line out, per connection):
 *   client connects, writes one line: base64(dataToSign) + "\n"
 *   server writes back one line: base64(signedResult) + "\n"        (success)
 *                            or: "ERROR: <message>" + "\n"          (failure)
 *   server closes the connection after responding.
 *
 * Usage:
 *   java -cp ".:cm-sdk.jar:cm-common.jar:common.jar:bcprov-jdk15on-1.70.jar" \
 *        PgwySignServer <p12file> <password> <port> [threads]
 *
 * Test directly with bash, no extra tooling needed:
 *   exec 3<>/dev/tcp/127.0.0.1/9600
 *   echo "<base64 dataToSign>" >&3
 *   head -n1 <&3
 *   exec 3<&- 3>&-
 */
public class PgwySignServer {

    private static PrivateKey privateKey;
    private static X509Certificate cert;

    public static void main(String[] args) {
        if (args.length < 3 || args.length > 4) {
            System.err.println("Usage: PgwySignServer <p12file> <password> <port> [threads]");
            System.exit(1);
        }
        String p12file  = args[0];
        String password = args[1];
        int port        = Integer.parseInt(args[2]);
        int threads      = args.length == 4 ? Integer.parseInt(args[3]) : 8;

        try {
            loadKey(p12file, password);
        } catch (Exception e) {
            System.err.println("FATAL: could not load key from " + p12file + ": " + e.getMessage());
            System.exit(1);
        }
        System.err.println("Loaded officer certificate: " + cert.getSubjectDN());

        ExecutorService pool = Executors.newFixedThreadPool(threads);
        try (ServerSocket server = new ServerSocket(port)) {
            System.err.println("PgwySignServer listening on 127.0.0.1:" + port
                + " (threads=" + threads + "). Ctrl-C to stop.");
            while (true) {
                Socket sock = server.accept();
                pool.submit(() -> handleConnection(sock));
            }
        } catch (IOException e) {
            System.err.println("FATAL: server socket error: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void loadKey(String p12file, String password) throws Exception {
        KeyStore ks = KeyStore.getInstance("PKCS12");
        try (FileInputStream fis = new FileInputStream(p12file)) {
            ks.load(fis, password.toCharArray());
        }
        String alias = null;
        java.util.Enumeration<String> aliases = ks.aliases();
        while (aliases.hasMoreElements()) {
            String a = aliases.nextElement();
            if (ks.isKeyEntry(a)) { alias = a; break; }
        }
        if (alias == null) {
            throw new Exception("No key entry found in " + p12file);
        }
        privateKey = (PrivateKey) ks.getKey(alias, password.toCharArray());
        cert = (X509Certificate) ks.getCertificate(alias);
    }

    private static void handleConnection(Socket sock) {
        try (Socket s = sock;
             BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream()));
             OutputStream out = s.getOutputStream()) {

            String b64data = in.readLine();
            if (b64data == null || b64data.isEmpty()) {
                out.write(("ERROR: empty request\n").getBytes());
                return;
            }

            String result = signOne(b64data);
            out.write((result + "\n").getBytes());
            out.flush();
        } catch (Exception e) {
            try {
                sock.getOutputStream().write(("ERROR: " + e.getMessage() + "\n").getBytes());
            } catch (IOException ignored) {}
        }
    }

    // same signing logic as the original one-shot PgwySign.java, just reused
    // across many calls instead of running once per JVM invocation.
    private static String signOne(String b64data) throws Exception {
        byte[] dataToSign = Base64.getDecoder().decode(b64data);

        SignedData sd = new SignedData(dataToSign, false);
        sd.addCertificate(cert);
        sd.addSigner(privateKey, cert, (Attribute[]) null, (Attribute[]) null, (String) null);

        SignedMessage sm = new SignedMessage(sd);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        DerEncode encoder = new DerEncode(baos);
        sm.encode(encoder);

        return Base64.getEncoder().encodeToString(baos.toByteArray());
    }
}
