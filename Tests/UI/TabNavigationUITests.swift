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
