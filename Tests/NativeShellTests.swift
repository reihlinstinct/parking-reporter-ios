import XCTest
@testable import ParkingReporter

final class NativeShellTests: XCTestCase {
    func testLanguageResolutionPrefersPreviewFlags() {
        XCTAssertEqual(ReviewLanguage.resolve(arguments: ["--preview-en"], preferred: ["he-IL"]), .english)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: ["--preview-he"], preferred: ["en-US"]), .hebrew)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["he-IL"]), .hebrew)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: ["fr-FR"]), .english)
        XCTAssertEqual(ReviewLanguage.resolve(arguments: [], preferred: []), .english)
    }
    func testHebrewIsRightToLeft() {
        XCTAssertEqual(ReviewLanguage.hebrew.direction, .rightToLeft)
        XCTAssertEqual(ReviewLanguage.english.direction, .leftToRight)
    }
    func testTimeFormatIsReadable24HourWithoutTimezone() {
        let utc = TimeZone(identifier: "UTC")!
        let noon = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01 12:00 UTC
        XCTAssertEqual(ReportTimeFormat.string(from: noon, timeZone: utc), "01/01/2026 12:00")
        let evening = noon.addingTimeInterval(7 * 3600 + 5 * 60)
        XCTAssertEqual(ReportTimeFormat.string(from: evening, timeZone: utc), "01/01/2026 19:05")
    }
    func testSampleReportsAreSyntheticAndGroupedNewestFirst() {
        let items = SampleReports.all()
        XCTAssertEqual(items.count, 3)
        let groups = SampleReports.grouped(items)
        XCTAssertEqual(groups.drafts.count, 1)
        XCTAssertEqual(groups.others.count, 2)
        XCTAssertTrue(groups.others[0].date > groups.others[1].date)
        XCTAssertTrue(items.allSatisfy { !$0.addressEn.isEmpty && !$0.addressHe.isEmpty && $0.address(.hebrew) != $0.address(.english) })
    }
    func testEveryCategoryHasHebrewAndEnglishTitles() {
        for category in ReportCategory.allCases {
            XCTAssertFalse(category.title(.hebrew).isEmpty)
            XCTAssertFalse(category.title(.english).isEmpty)
            XCTAssertNotEqual(category.title(.hebrew), category.title(.english))
        }
    }
}
