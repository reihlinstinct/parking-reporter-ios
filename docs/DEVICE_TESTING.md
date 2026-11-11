# בדיקה על מכשיר אמיתי וסימולטור / Testing on a real device and simulator

**Status:** nothing in this file was run on a real device by the authors. Items marked
VERIFIED come from Apple's published pages (links below). Items marked UNVERIFIED are
expected to work but have not been tried. Everything is free: no paid developer
account and no credit card. The app uses synthetic data only. Real filing is off.

## מה נבדק ומה לא (Verified and unverified)

| נושא / Topic | מצב / Status |
| --- | --- |
| Xcode 26.x and 16.x can deploy to iOS 15 devices and run iOS 15+ simulators | VERIFIED, Apple system requirements |
| Xcode 27.x supports devices and simulators on iOS 17+ only | VERIFIED, Apple system requirements |
| Wireless run after one cable pairing (iOS 11+) | VERIFIED, Apple Xcode help |
| Free Personal Team signing works for this project without edits | UNVERIFIED, no Mac was available |
| Free profile lasts 7 days, about 3 apps per device | UNVERIFIED against Apple, from third-party docs |
| The app runs on an iPhone 6s with iOS 15 | UNVERIFIED, needs a manual check on the device |

## איזה Xcode ואיזה macOS (Which Xcode and macOS)

| Xcode | macOS needed | Device iOS | Simulator iOS |
| --- | --- | --- | --- |
| 27.x | Tahoe 26.6 or later | 17 or later | 17 or later |
| 26.4 to 26.6 | Tahoe 26.2 or later | 15 or later | 15 or later |
| 26.0 to 26.3 | Sequoia 15.6 or later, or Tahoe | 15 or later | 15 or later |
| 16.x | Sonoma 14.5 or later (16.3 and 16.4 need Sequoia 15.2 or later) | 15 or later | 15 or later |

Source: https://developer.apple.com/xcode/system-requirements/ (checked 11 Nov 2026).

- iPhone 6s (up to iOS 15): use Xcode 26.x or 16.x. Not Xcode 27.
- iPhone 11 (iOS 15 up to the newest): Xcode 26.x or 16.x for iOS 15 to 26.x. For iOS 27 use Xcode 27.x.
  Whether Xcode 26.x can debug a phone already on iOS 27 is UNVERIFIED, so match Xcode to the phone.
- One Xcode 26.x install covers iOS 15 to 26.x for both phones.

## שלבים: מכשיר עם Xcode (Steps: device with Xcode)

1. בדוק את גרסת macOS (תפריט Apple > אודות ה-Mac) ובחר Xcode לפי הטבלה.
2. התקן Xcode (חינם) והתקן את רכיב iOS כשהוא מבקש.
3. התקן XcodeGen: `brew install xcodegen`.
4. הורד את הקוד והרץ `xcodegen generate` בתיקיית הפרויקט.
5. פתח את `ParkingReporter.xcodeproj`.
6. ב-Xcode: Settings > Accounts > הוסף Apple ID רגיל (בלי תשלום).
7. בחר את היעד ParkingReporter > Signing & Capabilities > Automatically manage signing > Team: Personal Team.
8. שנה את ה-Bundle Identifier למשהו ייחודי שלך (למשל `com.yourname.parkingreporter`). אל תעשה commit לשינוי הזה.
9. חבר את האייפון בכבל, פתח נעילה ולחץ Trust. ב-iOS 16 ומעלה הפעל Settings > Privacy & Security > Developer Mode והפעל מחדש.
10. בחר את האייפון בראש חלון Xcode ולחץ Run (Cmd+R). בפעם הראשונה: Settings > General > VPN & Device Management > Trust.
11. האפליקציה תעבוד כ-7 ימים. אחר כך חבר ולחץ Run שוב.

English:

1. Check the macOS version and pick an Xcode from the table.
2. Install Xcode (free) and let it install the iOS component.
3. Install XcodeGen: `brew install xcodegen`.
4. Clone the repo and run `xcodegen generate` in its folder.
5. Open `ParkingReporter.xcodeproj`.
6. Xcode > Settings > Accounts: add a normal Apple ID (no payment).
7. Target ParkingReporter > Signing & Capabilities > Automatically manage signing > Team: your Personal Team.
8. Change the Bundle Identifier to one that is unique to you. Do not commit that change.
9. Connect the iPhone by cable, unlock, tap Trust. On iOS 16+ turn on Settings > Privacy & Security > Developer Mode and restart.
10. Pick the iPhone at the top of Xcode and press Run (Cmd+R). First run: Settings > General > VPN & Device Management > Trust your Apple ID.
11. The app runs for about 7 days. Reconnect and press Run again after that.

`project.yml` sets `CODE_SIGNING_REQUIRED: NO` and an ad-hoc identity so CI can build a simulator app.
Steps 7 and 8 change the signing settings in Xcode only, on your machine.

## Wi-Fi after the first cable pairing

VERIFIED (https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html): Window > Devices and
Simulators > connect by cable > select the device > Connect via network > unplug. Later runs work over
the same Wi-Fi network. Needs iOS 11 or later on the device.

## סימולטור (Simulator)

1. Xcode > Settings > Components > Other Installed Platforms > Add Platforms.
2. Pick iOS 15.x, 16.x or 17.x and press Get. Each is several GB.
3. Command line alternative: `xcodebuild -downloadPlatform iOS -buildVersion 15.5`.
4. If a runtime shows as unavailable on Apple silicon, run `softwareupdate --install-rosetta` (community report, UNVERIFIED for 15 to 17).
5. Xcode 27.x cannot run iOS 15 or 16 simulators. Use Xcode 26.x for those.

Source: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components.md

CI does not run iOS 15 to 17 simulators: the free runner images do not ship them (macos-14 had 17.x and is
retired on 2 Nov 2026). See [COMPATIBILITY.md](COMPATIBILITY.md).
