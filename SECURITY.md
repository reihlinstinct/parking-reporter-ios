# Security

Development preview only. Do not use real profiles in CI or attach private photos, credentials, identifiers or decrypted reports to public issues.

No remote destination, authentication token or production key is present. No report is filed. A future network path requires enrolled device keys, independent receiver pinning, exact payload/image review, abuse controls and a separate go-live decision.

Local profile encryption uses Apple's CryptoKit AES-GCM, with a random 256-bit device-only Keychain key. This does not protect an unlocked compromised phone. A missing or unreadable key must not silently overwrite an existing encrypted profile. Deleting the app alone does not guarantee Keychain removal.

The Tink test imports synthetic test-only private keys solely inside a test bundle. Never enable cleartext key import in an app. Java/Objective-C compatibility must be demonstrated in both directions with complete canonical fixtures before any production package encryption is enabled.

Report a vulnerability through GitHub private vulnerability reporting if enabled. Otherwise open a public issue containing only a generic description and request a private channel. Do not publish exploitable details or sensitive data.
