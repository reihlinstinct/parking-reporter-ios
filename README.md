# Parking Reporter for iOS

MIT-licensed, offline-first development preview. Deployment target iOS 15.0, including iPhone 6s. No report submission, network transport, enrollment, production key or analytics SDK.

## First preview

- Camera or system photo picker, local Apple Vision text recognition.
- Plate candidates with explicit manual correction. Candidates are not proof.
- Reporter profile encrypted by CryptoKit AES-GCM with a device-only, when-unlocked Keychain key. Profile file excluded from backup. Explicit delete removes file and key. Photos stay in RAM in this preview.
- Simulator-only ad-hoc-signed build and unit tests on public macOS CI only.
- Separate pinned-source Tink Objective-C compatibility spike. Not linked to the app. Test-only private keys are generated at run time, never shipped or uploaded as artifacts.

## Open on a Mac

Install Xcode and XcodeGen (`brew install xcodegen`), then run `xcodegen generate`. Open `ParkingReporter.xcodeproj` and choose the ParkingReporter scheme. Select your iPhone, enable signing for your local build and choose your own Personal Team. No paid developer enrollment is required for a local test. Free provisioning expires after 7 days. Do not commit signing identities or local project state.

CI builds a simulator app, not an installable signed iPhone package. Camera, permissions, iOS 15 performance and profile persistence require physical-device testing. The UI is currently English; Hebrew localization is a next milestone.

## Status

Initial code is not a released app. CI and actual screenshot review must pass before the preview is considered ready. The Tink spike initially tests Java-to-Objective-C decryption/signature and tamper rejection plus Objective-C-to-Java roundtrip against synthetic PRPKG2 fixtures. It does not prove full report canonicalization, safe JPEG decoding, enrollment, transport or municipal submission. Those remain release gates.

## Crypto sources

- https://github.com/tink-crypto/tink-objc
- https://github.com/tink-crypto/tink-objc/releases
- https://repo.maven.apache.org/maven2/com/google/crypto/tink/tink/1.23.0/tink-1.23.0.pom

Tink ObjC is minimally maintained. It is built from source at commit `72166ba925e693c4004d5099d2d31e10c655e216` (v1.8.0), whose minimum iOS version is 15.0. No hand-written hybrid crypto is used.
