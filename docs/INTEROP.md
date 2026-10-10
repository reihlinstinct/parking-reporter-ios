# Tink compatibility spike

The Android source has no checked-in cross-language golden vectors. Its offline receiver documentation explicitly lists them as a remaining release gate. This repo does not claim they exist.

The first spike pins Java Tink 1.23.0 and Objective-C Tink source v1.8.0 commit `72166ba925e693c4004d5099d2d31e10c655e216`. Java generates fresh synthetic receiver/signing keys and PRPKG2 framing, signs `parking-intake-tink-v1 || plaintext`, adds a big-endian signature length, and encrypts with ECIES P256/HKDF SHA256/AES128-GCM using the same context. Objective-C must decrypt the Java ciphertext, compare the exact plaintext, verify the ECDSA signature and reject altered ciphertext, changed context and a changed signed message.

The fixture deliberately is not a valid report or valid decoded photograph. This is primitive/framing compatibility only, not full Android receiver parity. Complete UTF-8/canonical-report digest vectors, reverse-direction tests, bounds validation and JPEG decode are next gates. No production crypto is enabled in the app.

Java fixture generation was run locally. Objective-C build and XCTest require the public macOS job. The app stays offline whether this spike succeeds or fails.
