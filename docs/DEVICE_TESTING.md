# בדיקה על מכשיר אמיתי וסימולטור / Testing on a real device and simulator

עברית קודם, אנגלית אחריה. The Hebrew section comes first, English follows. Both say the same things.

## עברית

**סטטוס: לא הורץ על מכשיר.** המחברים לא הריצו את האפליקציה על מכשיר אמיתי או על Mac. סימון "מאומת" פירושו שהמידע לקוח מדפי Apple (הקישורים למטה). סימון "לא מאומת" פירושו שצפוי לעבוד אבל לא נוסה. הכול חינם: בלי חשבון מפתח בתשלום ובלי כרטיס אשראי. האפליקציה משתמשת בנתונים סינתטיים בלבד. הגשה אמיתית כבויה.

| נושא | מצב |
| --- | --- |
| Xcode 26 ו-16 פורסים למכשיר iOS 15 ומריצים סימולטור iOS 15 ומעלה | מאומת (דרישות המערכת של Apple) |
| Xcode 27 תומך במכשיר ובסימולטור iOS 17 ומעלה בלבד | מאומת (דרישות המערכת של Apple) |
| הרצה בלי כבל אחרי חיבור ראשון בכבל (iOS 11 ומעלה) | מאומת (עזרת Xcode של Apple) |
| חתימה חינמית עם Personal Team עובדת בפרויקט הזה בלי שינויי קוד | לא מאומת (לא היה Mac) |
| פרופיל חינמי תקף 7 ימים, כ-3 אפליקציות למכשיר | לא מאומת מול Apple (מקורות צד שלישי) |
| האפליקציה עובדת על iPhone 6s עם iOS 15 | לא מאומת (דרושה בדיקה ידנית במכשיר) |

### איזה Xcode ואיזה macOS

| Xcode | macOS נדרש | iOS במכשיר | iOS בסימולטור |
| --- | --- | --- | --- |
| 27.x | Tahoe 26.6 ומעלה | 17 ומעלה | 17 ומעלה |
| 26.4 עד 26.6 | Tahoe 26.2 ומעלה | 15 ומעלה | 15 ומעלה |
| 26.0 עד 26.3 | Sequoia 15.6 ומעלה, או Tahoe | 15 ומעלה | 15 ומעלה |
| 16.x | Sonoma 14.5 ומעלה (16.3 ו-16.4 דורשים Sequoia 15.2 ומעלה) | 15 ומעלה | 15 ומעלה |

מקור: https://developer.apple.com/xcode/system-requirements/ (נבדק ב-11 בנובמבר 2026).

- iPhone 6s (עד iOS 15): Xcode 26 או 16. לא Xcode 27.
- iPhone 11 (iOS 15 ועד החדש ביותר): Xcode 26 או 16 עבור iOS 15 עד 26. עבור iOS 27 יש להשתמש ב-Xcode 27. אם Xcode 26 יכול לנפות שגיאות בטלפון שכבר על iOS 27 הוא לא מאומת, לכן התאם את Xcode לגרסת ה-iOS של הטלפון.
- התקנה אחת של Xcode 26 מכסה iOS 15 עד 26 בשני הטלפונים.

### שלבים: מכשיר עם Xcode

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

ב-`project.yml` מוגדר `CODE_SIGNING_REQUIRED: NO` וזהות ad-hoc כדי ש-CI יבנה אפליקציית סימולטור. שלבים 7 ו-8 משנים את הגדרות החתימה ב-Xcode בלבד, במחשב שלך.

### Wi-Fi אחרי חיבור ראשון בכבל (מאומת)

Window > Devices and Simulators > חבר בכבל > בחר את המכשיר > Connect via network > נתק את הכבל. אחר כך Run עובד באותה רשת Wi-Fi. נדרש iOS 11 ומעלה במכשיר. מקור: https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html

### סימולטור

1. Xcode > Settings > Components > Other Installed Platforms > Add Platforms.
2. בחר iOS 15.x, 16.x או 17.x ולחץ Get. כל אחד תופס כמה GB.
3. חלופה בשורת פקודה: `xcodebuild -downloadPlatform iOS -buildVersion 15.5`.
4. אם סביבת הרצה מופיעה כלא זמינה ב-Apple silicon, הרץ `softwareupdate --install-rosetta` (דיווח מהקהילה, לא מאומת ל-15 עד 17).
5. Xcode 27 לא מריץ סימולטור iOS 15 או 16. השתמש ב-Xcode 26 עבורם.

מקור: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components.md

ב-CI לא רצים סימולטורים של iOS 15 עד 17, כי תמונות הרצה החינמיות לא כוללות אותם (ב-macos-14 היה iOS 17 והיא מתוכננת לפרישה ב-2 בנובמבר 2026). ראה [COMPATIBILITY.md](COMPATIBILITY.md).

## English

**Status: not run on a device.** The authors did not run the app on a real device or on a Mac. "Verified" means the information comes from Apple's published pages (links below). "Unverified" means expected to work but not tried. Everything is free: no paid developer account and no credit card. The app uses synthetic data only. Real filing is off.

| Topic | Status |
| --- | --- |
| Xcode 26 and 16 deploy to iOS 15 devices and run iOS 15+ simulators | Verified (Apple system requirements) |
| Xcode 27 supports devices and simulators on iOS 17+ only | Verified (Apple system requirements) |
| Wireless run after one cable pairing (iOS 11+) | Verified (Apple Xcode help) |
| Free Personal Team signing works for this project without code changes | Unverified (no Mac was available) |
| Free profile lasts 7 days, about 3 apps per device | Unverified against Apple (third-party docs) |
| The app runs on an iPhone 6s with iOS 15 | Unverified (needs a manual check on the device) |

### Which Xcode and macOS

| Xcode | macOS needed | Device iOS | Simulator iOS |
| --- | --- | --- | --- |
| 27.x | Tahoe 26.6 or later | 17 or later | 17 or later |
| 26.4 to 26.6 | Tahoe 26.2 or later | 15 or later | 15 or later |
| 26.0 to 26.3 | Sequoia 15.6 or later, or Tahoe | 15 or later | 15 or later |
| 16.x | Sonoma 14.5 or later (16.3 and 16.4 need Sequoia 15.2 or later) | 15 or later | 15 or later |

Source: https://developer.apple.com/xcode/system-requirements/ (checked 11 Nov 2026).

- iPhone 6s (up to iOS 15): use Xcode 26 or 16. Not Xcode 27.
- iPhone 11 (iOS 15 up to the newest): Xcode 26 or 16 for iOS 15 to 26. For iOS 27 use Xcode 27. Whether Xcode 26 can debug a phone already on iOS 27 is unverified, so match Xcode to the phone's iOS.
- One Xcode 26 install covers iOS 15 to 26 for both phones.

### Steps: device with Xcode

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

`project.yml` sets `CODE_SIGNING_REQUIRED: NO` and an ad-hoc identity so CI can build a simulator app. Steps 7 and 8 change the signing settings in Xcode only, on your machine.

### Wi-Fi after the first cable pairing (verified)

Window > Devices and Simulators > connect by cable > select the device > Connect via network > unplug. Later runs work over the same Wi-Fi network. Needs iOS 11 or later on the device. Source: https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html

### Simulator

1. Xcode > Settings > Components > Other Installed Platforms > Add Platforms.
2. Pick iOS 15.x, 16.x or 17.x and press Get. Each is several GB.
3. Command line alternative: `xcodebuild -downloadPlatform iOS -buildVersion 15.5`.
4. If a runtime shows as unavailable on Apple silicon, run `softwareupdate --install-rosetta` (community report, unverified for 15 to 17).
5. Xcode 27 cannot run iOS 15 or 16 simulators. Use Xcode 26 for those.

Source: https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components.md

CI does not run iOS 15 to 17 simulators: the free runner images do not ship them (macos-14 had iOS 17 and is scheduled for retirement on 2 Nov 2026). See [COMPATIBILITY.md](COMPATIBILITY.md).
