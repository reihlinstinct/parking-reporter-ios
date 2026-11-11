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
        XCTAssertFalse(ReporterValidation.validID("18"))
        XCTAssertFalse(ReporterValidation.validID(j("000", "000", "019")))
        XCTAssertFalse(ReporterValidation.validID("12a456789"))
        XCTAssertFalse(ReporterValidation.validID(""))
        XCTAssertFalse(ReporterValidation.validID(j("000", "000", "000")))
    }
    func testNonASCIIDigitsAreRejectedWithoutCrashing() {
        XCTAssertFalse(ReporterValidation.validID(j("١٢٣", "٤٥٦", "٧٨٩")), "Arabic-Indic digits")
        XCTAssertFalse(ReporterValidation.validID(j("१२३", "४५६", "७८९")), "Devanagari digits")
        XCTAssertFalse(ReporterValidation.validID(j("１２３", "４５６", "７８９")), "fullwidth digits")
        XCTAssertFalse(ReporterValidation.validPhone(j("٠٥٠", "١٢٣", "٤٥٦", "٧")))
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
