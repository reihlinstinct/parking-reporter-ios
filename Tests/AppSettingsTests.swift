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
    }
    func testOnboardingGate() {
        let (settings, _) = makeSettings()
        XCTAssertTrue(settings.shouldShowOnboarding(arguments: []))
        XCTAssertFalse(settings.shouldShowOnboarding(arguments: ["--preview-en"]))
        XCTAssertTrue(settings.shouldShowOnboarding(arguments: ["--preview-en", "--preview-onboarding"]))
        settings.onboarded = true
        XCTAssertFalse(settings.shouldShowOnboarding(arguments: []))
    }
    func testPhoneValidation() {
        XCTAssertTrue(ReporterValidation.validPhone("0501234567"))
        XCTAssertTrue(ReporterValidation.validPhone("+972501234567"))
        XCTAssertTrue(ReporterValidation.validPhone("02-6234567"))
        XCTAssertFalse(ReporterValidation.validPhone("12345"))
        XCTAssertFalse(ReporterValidation.validPhone(""))
    }
    func testIsraeliIDChecksum() {
        XCTAssertTrue(ReporterValidation.validID("000000018"))
        XCTAssertTrue(ReporterValidation.validID("000018"))
        XCTAssertFalse(ReporterValidation.validID("18"))
        XCTAssertFalse(ReporterValidation.validID("000000019"))
        XCTAssertFalse(ReporterValidation.validID("12a456789"))
        XCTAssertFalse(ReporterValidation.validID(""))
    }
    func testEmailAndName() {
        XCTAssertTrue(ReporterValidation.validEmail(""))
        XCTAssertTrue(ReporterValidation.validEmail("a@b.co"))
        XCTAssertFalse(ReporterValidation.validEmail("a@b"))
        XCTAssertTrue(ReporterValidation.validName("Dana"))
        XCTAssertFalse(ReporterValidation.validName("  "))
    }
}
