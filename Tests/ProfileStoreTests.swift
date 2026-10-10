import XCTest
@testable import ParkingReporter
final class ProfileStoreTests: XCTestCase {
    func testSaveLoadDeleteOnDeviceKeychain() throws {
        let store = ProfileStore()
        try store.delete()
        defer { try? store.delete() }
        let profile = ReporterProfile(first: "Synthetic", last: "Only", phone: "000", identifier: "000", email: "test@example.invalid")
        try store.save(profile)
        XCTAssertEqual(try store.load(), profile)
        var changed = profile; changed.first = "Changed"
        try store.save(changed)
        XCTAssertEqual(try store.load(), changed)
        try store.delete()
        XCTAssertEqual(try store.load(), ReporterProfile())
    }
}
