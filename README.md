# Parking Reporter for iOS

Planned native Swift app for local parking-evidence review on iOS 15 and later.
No live report submission. MIT licensed.

## Status: main is repository scaffolding

The default branch currently contains repository guidance, a safety-pattern
scanner and isolated signing-test workflows. It does **not** contain an Xcode
app project, a runnable preview or a released iOS app.

Development work is separate and unmerged:

- [Draft preview and crypto spike](https://github.com/reihlinstinct/parking-reporter-ios/pull/2):
  proposed SwiftUI capture/review, Vision plate candidates, encrypted local
  reporter settings and synthetic encryption-interoperability tests.
- [Draft RTL review design](https://github.com/reihlinstinct/parking-reporter-ios/pull/4):
  proposed compact Hebrew review, stacked on the preview work.

A draft PR description is not an acceptance result. Build, interoperability,
privacy, real-device iOS 15 behavior and small-screen review still need verified
results before any install-ready or compatibility claim.

## Product direction

Use native Swift, on-device Apple Vision and Keychain storage. Keep the Android
app separate. Target iOS 15, including small-screen devices; do not infer tested
support from the deployment target. Initial installation is intended through
Xcode on a Mac, without a paid distribution service. Installation instructions
belong with a reviewed, buildable app, not this scaffold.

Do not bundle reporter details, municipal credentials or production encryption
keys. Keep real photos and personal data out of this public repository, test
fixtures, issues and CI artifacts. Use synthetic examples only.

## Available local check

From the repository root, using Python 3:

```sh
python3 scripts/check_repository.py
```

This checks selected text patterns only. It is not a complete secret detector,
privacy audit, app test or evidence that a build works. Human review is still
required. There is no app build command for the current default branch.

The manual signing workflow creates an isolated empty test commit; it is not an
app build or a documentation validation step and should not be dispatched for
this check. The signing-safety workflow covers changes to its workflow files,
not general README or app correctness.

## Contributing

Start with an issue, use a small signed PR and describe verification and limits.
Keep implementation claims tied to merged code and actual test results.
See [contributing](CONTRIBUTING.md), [security](SECURITY.md) and [license](LICENSE).
