// Test-only keys and fake data generated in CI. Never use these keys in an app.
import com.google.crypto.tink.*;
import com.google.crypto.tink.config.TinkConfig;
import com.google.crypto.tink.hybrid.*;
import com.google.crypto.tink.signature.*;
import java.nio.*;
import java.nio.file.*;
import java.io.*;
import java.util.*;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import com.google.gson.*;

public class Generate {
  public static void main(String[] args) throws Exception {
    TinkConfig.register();
    Path out = Path.of(args[0]); Files.createDirectories(out);
    if (args.length > 1) { verifyReverse(out, Path.of(args[1])); return; }
    KeysetHandle receiver = KeysetHandle.generateNew(HybridKeyTemplates.ECIES_P256_HKDF_HMAC_SHA256_AES128_GCM);
    KeysetHandle signer = KeysetHandle.generateNew(SignatureKeyTemplates.ECDSA_P256);
    byte[] context = "parking-intake-tink-v1".getBytes(java.nio.charset.StandardCharsets.UTF_8);
    // Fixed fake report covers sorted nested keys, Hebrew UTF-8, quotes and exact JPEG hashes.
    byte[] jpeg = Base64.getDecoder().decode(Files.readString(Path.of(args[0]).getParent().resolve("synthetic-jpeg.base64")).trim());
    JsonObject report = new JsonObject();
    report.addProperty("schema", 1); report.addProperty("id", "synthetic-vector-1");
    report.addProperty("original_sha256", sha(jpeg)); report.addProperty("outgoing_sha256", sha(jpeg));
    report.addProperty("review_digest", "a".repeat(64)); report.addProperty("plate", "1234567");
    report.addProperty("address", "רחוב בדיקה 1"); report.addProperty("subject", "sidewalk_parking");
    report.addProperty("exact_text", "בדיקה \"סינתטית\"\nבלבד"); report.addProperty("time", "2026-01-01T12:00:00Z");
    report.addProperty("latitude", 31.0); report.addProperty("longitude", 35.0);
    JsonObject profile = new JsonObject(); profile.addProperty("first", "Synthetic"); profile.addProperty("last", "Only");
    profile.addProperty("phone", "000"); profile.addProperty("id", "000"); profile.addProperty("email", "test@example.invalid");
    report.add("reporter", profile);
    String approval = sha(canonical(report).getBytes(StandardCharsets.UTF_8));
    JsonObject envelope = new JsonObject(); envelope.add("report", report); envelope.addProperty("approval_digest", approval);
    byte[] header = canonical(envelope).getBytes(StandardCharsets.UTF_8);
    if (!approval.equals("ded3edbe631520adfd72936a951f487c0e30cf7a9e5bfaf40d5f195efc8cc87b")) throw new Exception("Canonical golden digest changed");
    Files.write(out.resolve("canonical-header.bin"), header); Files.write(out.resolve("jpeg.bin"), jpeg);
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
    try (OutputStream stream = Files.newOutputStream(out.resolve("signer-test-only.bin"))) {
      CleartextKeysetHandle.write(signer, BinaryKeysetWriter.withOutputStream(stream));
    }
    try (OutputStream stream = Files.newOutputStream(out.resolve("receiver-public.bin"))) {
      CleartextKeysetHandle.write(receiver.getPublicKeysetHandle(), BinaryKeysetWriter.withOutputStream(stream));
    }
    Files.write(out.resolve("context.bin"), context); Files.write(out.resolve("plain.bin"), plain);
    Files.write(out.resolve("ciphertext.bin"), ciphertext);
    System.out.println("Synthetic Java Tink 1.23.0 fixture generated. Test-only private key.");
  }
  static String sha(byte[] bytes) throws Exception {
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes); StringBuilder s = new StringBuilder();
    for (byte b : digest) s.append(String.format("%02x", b)); return s.toString();
  }
  // Same restricted object/string/boolean/number/null ordering as Android EncryptedPackage.canonical.
  static String canonical(JsonElement value) {
    if (value.isJsonObject()) {
      List<String> keys = new ArrayList<>(value.getAsJsonObject().keySet()); Collections.sort(keys);
      List<String> fields = new ArrayList<>();
      for (String k : keys) fields.add(quote(k)+":"+canonical(value.getAsJsonObject().get(k)));
      return "{"+String.join(",",fields)+"}";
    }
    if (value.isJsonNull()) return "null";
    JsonPrimitive p=value.getAsJsonPrimitive(); return p.isString()?quote(p.getAsString()):p.toString();
  }
  static String quote(String text) {
    StringBuilder s = new StringBuilder("\""); char previous=0;
    for (char c : text.toCharArray()) {
      switch(c) {
        case '\\': s.append("\\\\"); break;
        case '"': s.append("\\\""); break;
        case '/': if(previous=='<') s.append('\\'); s.append(c); break;
        case '\b': s.append("\\b"); break;
        case '\t': s.append("\\t"); break;
        case '\n': s.append("\\n"); break;
        case '\f': s.append("\\f"); break;
        case '\r': s.append("\\r"); break;
        default:
          if(c<32 || (c>=0x80&&c<0xa0) || (c>=0x2000&&c<0x2100)) s.append(String.format("\\u%04x",(int)c));
          else s.append(c);
      }
      previous=c;
    }
    return s.append('"').toString();
  }
  static void verifyReverse(Path fixtures, Path output) throws Exception {
    KeysetHandle receiver=CleartextKeysetHandle.read(BinaryKeysetReader.withBytes(Files.readAllBytes(fixtures.resolve("receiver-test-only.bin"))));
    KeysetHandle signer=CleartextKeysetHandle.read(BinaryKeysetReader.withBytes(Files.readAllBytes(fixtures.resolve("signer-public.bin"))));
    byte[] context=Files.readAllBytes(fixtures.resolve("context.bin"));
    byte[] cipher=Files.readAllBytes(output.resolve("objc-ciphertext.bin"));
    byte[] signed=receiver.getPrimitive(HybridDecrypt.class).decrypt(cipher,context);
    ByteBuffer b=ByteBuffer.wrap(signed); int n=b.getInt();
    if(n<=0||n>256||b.remaining()<=n+10) throw new Exception("Invalid signature framing");
    byte[] sig=new byte[n]; b.get(sig); byte[] plain=new byte[b.remaining()];b.get(plain);
    signer.getPrimitive(PublicKeyVerify.class).verify(sig,concat(context,plain));
    if(!Arrays.equals(plain,Files.readAllBytes(fixtures.resolve("plain.bin"))))throw new Exception("Reverse plaintext mismatch");
    System.out.println("Objective-C -> Java Tink decrypt/signature/exact PRPKG2 bytes verified");
  }
  static byte[] concat(byte[] a, byte[] b) { return ByteBuffer.allocate(a.length+b.length).put(a).put(b).array(); }
}
