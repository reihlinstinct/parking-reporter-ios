import XCTest
@testable import ParkingReporter
final class CategoryReviewTests: XCTestCase {
    func testOnlyVehicleCategoryContainsPlate() throws {
        var draft = CategoryReviewDraft()
        draft.correctPlate("1234567"); XCTAssertNil(draft.plate)
        draft.select(.sidewalkParking); draft.correctPlate("1234567"); XCTAssertEqual(draft.plate, "1234567")
        draft.select(.brokenSign); XCTAssertNil(draft.plate)
        let json = String(data: try JSONEncoder().encode(draft), encoding: .utf8)!
        XCTAssertFalse(json.contains("plate"))
        draft.select(.fadedCrosswalk); draft.correctPlate("7654321"); XCTAssertNil(draft.plate)
    }
    func testClassifierSuggestionHasSameRulesAndDoesNotRestoreOldPlate() {
        var draft = CategoryReviewDraft()
        draft.select(.sidewalkParking); draft.correctPlate("1234567")
        draft.suggest(.fadedCrosswalk); XCTAssertNil(draft.plate)
        draft.suggest(.sidewalkParking); XCTAssertNil(draft.plate)
    }
}
