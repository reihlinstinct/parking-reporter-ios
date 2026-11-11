# iOS compatibility

Baseline: iOS 15.0, so older iPhones (6s and up) keep working. Anything newer
must sit behind `#available` with a fallback, and each fallback is listed here.

CI runs the full unit and UI test suite on a simulator matrix (workflow
`iOS compatibility matrix`): iOS 15.5, 16.4, 17.5 and the newest runtime on the
runner image. The newest-runtime job gates merges. The older runtimes are
downloaded on demand and start as non-blocking until they have run reliably.

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
