// Test-only keys and fake data generated in CI. Never use these keys in an app.
import com.google.crypto.tink.*;
import com.google.crypto.tink.config.TinkConfig;
import com.google.crypto.tink.hybrid.*;
import com.google.crypto.tink.signature.*;
import java.nio.*;
import java.nio.file.*;
import java.io.*;
import java.util.*;

public class Generate {
  public static void main(String[] args) throws Exception {
    TinkConfig.register();
    Path out = Path.of(args[0]); Files.createDirectories(out);
    KeysetHandle receiver = KeysetHandle.generateNew(HybridKeyTemplates.ECIES_P256_HKDF_HMAC_SHA256_AES128_GCM);
    KeysetHandle signer = KeysetHandle.generateNew(SignatureKeyTemplates.ECDSA_P256);
    byte[] context = "parking-intake-tink-v1".getBytes(java.nio.charset.StandardCharsets.UTF_8);
    // Framing follows Android EncryptedPackage.kt. Synthetic fixture only, not a valid report.
    byte[] header = "{\"approval_digest\":\"synthetic\",\"report\":{\"schema\":1}}".getBytes(java.nio.charset.StandardCharsets.UTF_8);
    byte[] jpeg = new byte[]{(byte)255,(byte)216,(byte)255,(byte)217};
    byte[] plain = ByteBuffer.allocate(10 + header.length + jpeg.length).put("PRPKG2".getBytes()).putInt(header.length).put(header).put(jpeg).array();
    byte[] toSign = concat(context, plain);
    byte[] signature = signer.getPrimitive(PublicKeySign.class).sign(toSign);
    byte[] signed = ByteBuffer.allocate(4 + signature.length + plain.length).putInt(signature.length).put(signature).put(plain).array();
    byte[] ciphertext = receiver.getPublicKeysetHandle().getPrimitive(HybridEncrypt.class).encrypt(signed, context);
    try (OutputStream stream = Files.newOutputStream(out.resolve("receiver-test-only.bin"))) {
      CleartextKeysetHandle.write(receiver, BinaryKeysetWriter.withOutputStream(stream));
    }
    try (OutputStream stream = Files.newOutputStream(out.resolve("signer-public.bin"))) {
      CleartextKeysetHandle.write(signer.getPublicKeysetHandle(), BinaryKeysetWriter.withOutputStream(stream));
    }
    Files.write(out.resolve("context.bin"), context); Files.write(out.resolve("plain.bin"), plain);
    Files.write(out.resolve("ciphertext.bin"), ciphertext);
    System.out.println("Synthetic Java Tink 1.23.0 fixture generated. Test-only private key.");
  }
  static byte[] concat(byte[] a, byte[] b) { return ByteBuffer.allocate(a.length+b.length).put(a).put(b).array(); }
}
