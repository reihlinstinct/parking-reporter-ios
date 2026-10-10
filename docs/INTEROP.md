# Tink compatibility spike

The Android source had no checked-in cross-language golden vectors. This spike creates fixed synthetic report/header/JPEG golden bytes and regenerates test-only keys/ciphertexts at run time. No real report or private key is shipped.

Pinned Java Tink 1.23.0 and Objective-C v1.8.0 source commit `72166ba925e693c4004d5099d2d31e10c655e216` use ECIES P256/HKDF SHA256/AES128-GCM and ECDSA P256, with `parking-intake-tink-v1` as context/signature domain. Java-to-ObjC decryption/signature/tamper test passed in CI run 38068752891. New complete synthetic header/JPEG digest and reverse-direction checks are pending CI, not claimed yet.

The fixed report covers sorted nested keys, Hebrew UTF-8, quote/newline escaping, integer/double representations, exact approval SHA256 and outgoing JPEG SHA256. Objective-C reconstructs canonical bytes and requires equality. It signs and encrypts the same bytes, then Java must decrypt/verify them. Missing reverse output fails the job. Objective-C numeric formatting is restricted to this fixture, not a production canonicalizer.

This remains a test adapter, not a complete Android OfflineReceiver validation or production iOS sealer. The review_digest is synthetic; safe JPEG validation, enrollment, replay, exact user review and transport remain release gates. The app has no Tink/network submission path.
