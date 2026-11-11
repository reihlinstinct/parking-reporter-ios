# iOS compatibility

Baseline: iOS 15.0, so older iPhones (6s and up) keep working. Anything newer
must sit behind `#available` with a fallback, and each fallback is listed here.

CI runs the full unit and UI test suite on simulators (workflow `iOS compatibility matrix`):
the oldest and newest iOS runtime preinstalled on the macos-15 image, and the newest on the
macos-26 image. All three jobs block the PR.

No iOS 15.0 simulator is run. The free runner images do not ship that runtime, and the
workflow does not download runtimes, because a download has no pin or checksum to verify.
The iOS 15.0 baseline is enforced three other ways instead:
- the deployment target is 15.0, so the compiler rejects any newer API without `#available`
- a CI step checks that the built app declares `MinimumOSVersion` 15.0
- the Camera, permissions and performance check on a real iPhone 6s (below)

The runtimes the matrix actually used are printed at the top of each job log.

## Rules

- Use `NavigationView` with `.navigationViewStyle(.stack)`. `NavigationStack` needs iOS 16.
- Use one-parameter `onChange(of:)`. The two-parameter form needs iOS 17.
- No APIs above iOS 15 without `if #available` or `@available`.
- Fallbacks below are the contract. A new feature adds a row.

## Feature table

| Feature | Needs | Fallback on iOS 15 |
| --- | --- | --- |
| Tab bar, grouped lists, forms | iOS 15 | none needed |
| Prominent buttons (`.borderedProminent`) | iOS 15 | none needed |
| Photo picker (PHPicker) | iOS 14 | none needed |
| On-device text recognition (Vision) | iOS 13 | none needed |
| Bottom sheet detents | iOS 16 | full-height sheet |
| Siri and Shortcuts voice report (App Intents) | iOS 16 | Shortcuts action through a plain intent, or no voice entry |
| `NavigationStack` and `NavigationSplitView` | iOS 16 | not used |
| SwiftUI Charts (statistics) | iOS 16 | plain list of numbers |
| Live Activities | iOS 16.1 | not used |
| Tink-compatible encryption | iOS 15 (pinned build) | none needed |

Camera, permissions and performance on a real iPhone 6s still need a manual
check. Simulators do not cover them.
