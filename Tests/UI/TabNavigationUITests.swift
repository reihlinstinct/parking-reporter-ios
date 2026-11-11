import XCTest

final class TabNavigationUITests: XCTestCase {
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }
    func testEnglishTabsNavigate() {
        let app = launch(["--preview-en", "--preview-capture"])
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 20))
        XCTAssertTrue(tabs.buttons["Report"].exists)
        tabs.buttons["My reports"].tap()
        XCTAssertTrue(app.staticTexts["Vehicle on sidewalk"].waitForExistence(timeout: 10))
        tabs.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Reporter details"].waitForExistence(timeout: 10))
        app.staticTexts["Privacy"].tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 10))
    }
    func testHebrewTabsExist() {
        let app = launch(["--preview-he", "--preview-capture"])
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 20))
        XCTAssertTrue(tabs.buttons["דיווח"].exists)
        XCTAssertTrue(tabs.buttons["הדיווחים שלי"].exists)
        XCTAssertTrue(tabs.buttons["הגדרות"].exists)
    }
    func testNoSendEnabledInPreview() {
        let app = launch(["--preview-en"])
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20))
        let send = app.buttons["Send"]
        XCTAssertTrue(send.waitForExistence(timeout: 10))
        XCTAssertFalse(send.isEnabled)
    }
}

final class OnboardingUITests: XCTestCase {
    func testWelcomeThenSetupThenLaterShowsTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-en", "--preview-onboarding"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome to Clear Sidewalks"].waitForExistence(timeout: 20))
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.navigationBars["Basic setup"].waitForExistence(timeout: 10))
        app.buttons["onboarding.save"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'international number'")).firstMatch.waitForExistence(timeout: 10))
        app.buttons["onboarding.later"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }
    func testHebrewOnboardingIsRightToLeftCopy() {
        let app = XCUIApplication()
        app.launchArguments = ["--preview-he", "--preview-onboarding"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ברוכים הבאים למדרכות פנויות"].waitForExistence(timeout: 20))
    }
}
