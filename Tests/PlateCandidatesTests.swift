import XCTest
@testable import ParkingReporter
final class PlateCandidatesTests: XCTestCase {
    func testCandidates() {
        XCTAssertEqual(PlateCandidates.parse(["12-345-67", "123-45-678", "1234567"]), ["1234567", "12345678"])
    }
    func testRejectsEmbeddedAndWrongLengths() {
        XCTAssertEqual(PlateCandidates.parse(["AB1234567", "123456789", "123456", ""]), [])
    }
    func testProfileCodable() throws {
        let profile = ReporterProfile(first: "Test", last: "Only", phone: "000", identifier: "000", email: "test@example.invalid")
        XCTAssertEqual(try JSONDecoder().decode(ReporterProfile.self, from: JSONEncoder().encode(profile)), profile)
    }
}
