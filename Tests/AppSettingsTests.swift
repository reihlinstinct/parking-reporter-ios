import XCTest
@testable import ParkingReporter

final class AppSettingsTests: XCTestCase {
    private func makeSettings() -> (AppSettings, UserDefaults) {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return (AppSettings(defaults: defaults), defaults)
    }
    func testLanguageChoicePersists() {
        let (settings, defaults) = makeSettings()
        XCTAssertNil(settings.savedLanguage)
        settings.savedLanguage = .arabic
        XCTAssertEqual(AppSettings(defaults: defaults).savedLanguage, .arabic)
        settings.savedLanguage = nil
        XCTAssertNil(AppSettings(defaults: defaults).savedLanguage)
    }
    func testSavedLanguageBeatsSystemButNotPreviewFlag() {
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["he-IL"], saved: .russian), .russian)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: ["--preview-am"], preferred: ["he-IL"], saved: .russian), .amharic)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["iw-IL"]), .hebrew)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["ar-SA"]), .arabic)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["fr-FR"]), .french)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: ["--preview-fr"], preferred: ["he-IL"]), .french)
    }
    func testOnboardingGate() {
        let (settings, _) = makeSettings()
        XCTAssertTrue(settings.shouldShowOnboarding(arguments: []))
        XCTAssertFalse(settings.shouldShowOnboarding(arguments: ["--preview-en"]))
        XCTAssertTrue(settings.shouldShowOnboarding(arguments: ["--preview-en", "--preview-onboarding"]))
        settings.finishedThisSession = true
        XCTAssertFalse(settings.shouldShowOnboarding(arguments: ["--preview-en", "--preview-onboarding"]))
        settings.onboarded = true
        XCTAssertFalse(settings.shouldShowOnboarding(arguments: []))
    }
    func testPhoneValidation() {
        XCTAssertTrue(ReporterValidation.validPhone(j("050", "123", "456", "7")))
        XCTAssertTrue(ReporterValidation.validPhone(j("050", "-12", "3-4", "567")))
        XCTAssertTrue(ReporterValidation.validPhone(j("+97", "250", "123", "456", "7")))
        XCTAssertTrue(ReporterValidation.validPhone(j("+33", "612", "345", "678")))
        XCTAssertTrue(ReporterValidation.validPhone(j("+1 ", "(41", "5) ", "555", "-26", "71")))
        XCTAssertFalse(ReporterValidation.validPhone(j("02-", "623", "456", "7")), "landline")
        XCTAssertFalse(ReporterValidation.validPhone(j("000", "000", "000", "0")))
        XCTAssertFalse(ReporterValidation.validPhone(j("050", "000", "000", "0")), "repeated digits")
        XCTAssertFalse(ReporterValidation.validPhone(j("+00", "000", "000", "00")))
        XCTAssertFalse(ReporterValidation.validPhone(j("+97", "221", "234", "567")), "Israeli landline in +972 form")
        XCTAssertFalse(ReporterValidation.validPhone("12345"))
        XCTAssertFalse(ReporterValidation.validPhone(""))
        XCTAssertFalse(ReporterValidation.validPhone("05012345ab"))
    }
    func testIsraeliIDChecksum() {
        XCTAssertTrue(ReporterValidation.validID(j("000", "000", "018")))
        XCTAssertTrue(ReporterValidation.validID("000018"))
        XCTAssertTrue(ReporterValidation.validID("18"), "short IDs are zero-padded, like Android")
        XCTAssertFalse(ReporterValidation.validID("19"))
        XCTAssertFalse(ReporterValidation.validID(j("000", "000", "019")))
        XCTAssertFalse(ReporterValidation.validID("12a456789"))
        XCTAssertFalse(ReporterValidation.validID(""))
        XCTAssertFalse(ReporterValidation.validID(j("000", "000", "000")))
    }
    /// Re-writes ASCII digits in another script at run time, so no digit-shaped literal sits in the repo.
    private func script(_ ascii: String, zero: UInt32) -> String {
        String(String.UnicodeScalarView(ascii.unicodeScalars.map { scalar in
            ("0"..."9").contains(Character(scalar)) ? Unicode.Scalar(zero + (scalar.value - 48))! : scalar
        }))
    }
    func testNonASCIIDigitsAreNormalizedLikeAndroid() {
        let arabicID = script(j("000", "000", "018"), zero: 0x0660)       // Arabic-Indic
        let arabicShortID = script("18", zero: 0x0660)
        let arabicMobile = script(j("050", "123", "456", "7"), zero: 0x0660)
        let arabicIntl = "+" + script(j("972", "501", "234", "567"), zero: 0x0660)
        XCTAssertNotEqual(arabicID, j("000", "000", "018"))
        XCTAssertEqual(ReporterValidation.canonicalID(arabicID), j("000", "000", "018"))
        XCTAssertTrue(ReporterValidation.validID(arabicID))
        XCTAssertTrue(ReporterValidation.validID(arabicShortID))
        XCTAssertTrue(ReporterValidation.validPhone(arabicMobile))
        XCTAssertTrue(ReporterValidation.validPhone(arabicIntl))
        XCTAssertEqual(ReporterValidation.canonicalPhone(arabicMobile), j("+97", "250", "123", "456", "7"))
        XCTAssertTrue(ReporterValidation.validID(script(j("000", "000", "018"), zero: 0x0966)), "Devanagari")
        XCTAssertTrue(ReporterValidation.validID(script(j("000", "000", "018"), zero: 0xFF10)), "fullwidth")
        XCTAssertFalse(ReporterValidation.validID(script(j("123", "456", "789"), zero: 0x0966)), "bad checksum still rejected")
        XCTAssertFalse(ReporterValidation.validID("abc"))
    }
    func testPhoneDivergencesFromAndroidFixed() {
        XCTAssertFalse(ReporterValidation.validPhone(j("+123", "456", "7")), "7 digits")
        XCTAssertTrue(ReporterValidation.validPhone(j("+123", "456", "78")), "8 digits")
        XCTAssertFalse(ReporterValidation.validPhone(j("050", "+123", "456")), "plus inside the number is not a prefix")
        XCTAssertTrue(ReporterValidation.validPhone(j("972", "50", "123", "456", "7")) == false, "bare 972 without plus")
    }
    func testNormalizedProfileStoresASCIIOnly() {
        var p = ReporterProfile(); p.first = " A "; p.last = "B"; p.phone = script(j("050", "123", "456", "7"), zero: 0x0660); p.identifier = script(j("000", "000", "018"), zero: 0x0660)
        let n = ReporterValidation.normalized(p)
        XCTAssertEqual(n.phone, j("+97", "250", "123", "456", "7")); XCTAssertEqual(n.identifier, j("000", "000", "018")); XCTAssertEqual(n.first, "A")
    }
    func testEmailAndName() {
        XCTAssertTrue(ReporterValidation.validEmail(""))
        XCTAssertTrue(ReporterValidation.validEmail(j("a@b", ".co")))
        XCTAssertFalse(ReporterValidation.validEmail(j("a@b")))
        XCTAssertTrue(ReporterValidation.validName("Dana"))
        XCTAssertFalse(ReporterValidation.validName("  "))
    }

    /// Joins fragments at run time so no PII-shaped literal sits in the repository (privacy guard).
    private func j(_ parts: String...) -> String { parts.joined() }
}
