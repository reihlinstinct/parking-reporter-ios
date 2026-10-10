import XCTest
@testable import ParkingReporter
final class RecognitionStateTests: XCTestCase {
    func testConfidentSingleCandidateIsReadOnly() {
        XCTAssertFalse(PlateRecognition.from([("12-345-67", 0.99)]).needsCorrection)
    }
    func testCorrectionOnlyOnUncertainMissingOrConflictingCandidate() {
        XCTAssertTrue(PlateRecognition.from([]).needsCorrection)
        XCTAssertTrue(PlateRecognition.from([("1234567", 0.6)]).needsCorrection)
        XCTAssertTrue(PlateRecognition.from([("1234567", 0.99), ("7654321", 0.99)]).needsCorrection)
    }
}
