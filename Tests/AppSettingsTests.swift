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
        XCTAssertTrue(ReporterValidation.validPhone("0501234567"))
        XCTAssertTrue(ReporterValidation.validPhone("050-123-4567"))
        XCTAssertTrue(ReporterValidation.validPhone("+972501234567"))
        XCTAssertTrue(ReporterValidation.validPhone("+33612345678"))
        XCTAssertTrue(ReporterValidation.validPhone("+1 (415) 555-2671"))
        XCTAssertFalse(ReporterValidation.validPhone("02-6234567"), "landline")
        XCTAssertFalse(ReporterValidation.validPhone("0000000000"))
        XCTAssertFalse(ReporterValidation.validPhone("0500000000"), "repeated digits")
        XCTAssertFalse(ReporterValidation.validPhone("+0000000000"))
        XCTAssertFalse(ReporterValidation.validPhone("+97221234567"), "Israeli landline in +972 form")
        XCTAssertFalse(ReporterValidation.validPhone("12345"))
        XCTAssertFalse(ReporterValidation.validPhone(""))
        XCTAssertFalse(ReporterValidation.validPhone("05012345ab"))
    }
    func testIsraeliIDChecksum() {
        XCTAssertTrue(ReporterValidation.validID("000000018"))
        XCTAssertTrue(ReporterValidation.validID("000018"))
        XCTAssertFalse(ReporterValidation.validID("18"))
        XCTAssertFalse(ReporterValidation.validID("000000019"))
        XCTAssertFalse(ReporterValidation.validID("12a456789"))
        XCTAssertFalse(ReporterValidation.validID(""))
        XCTAssertFalse(ReporterValidation.validID("000000000"))
    }
    func testNonASCIIDigitsAreRejectedWithoutCrashing() {
        XCTAssertFalse(ReporterValidation.validID("١٢٣٤٥٦٧٨٩"), "Arabic-Indic digits")
        XCTAssertFalse(ReporterValidation.validID("१२३४५६७८९"), "Devanagari digits")
        XCTAssertFalse(ReporterValidation.validID("１２３４５６７８９"), "fullwidth digits")
        XCTAssertFalse(ReporterValidation.validPhone("٠٥٠١٢٣٤٥٦٧"))
    }
    func testEmailAndName() {
        XCTAssertTrue(ReporterValidation.validEmail(""))
        XCTAssertTrue(ReporterValidation.validEmail("a@b.co"))
        XCTAssertFalse(ReporterValidation.validEmail("a@b"))
        XCTAssertTrue(ReporterValidation.validName("Dana"))
        XCTAssertFalse(ReporterValidation.validName("  "))
    }
}
