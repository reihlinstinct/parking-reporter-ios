import XCTest
import Security
@testable import ParkingReporter

final class ProfileStoreTests: XCTestCase {
    func testSaveLoadDeleteWithIsolatedStore() throws {
        // Isolated names: this app-hosted test must never touch a developer's real profile.
        let id = UUID().uuidString
        let store = ProfileStore(service: "org.sidewalks.ParkingReporter.tests.roundtrip.\(id)",
                                 account: "roundtrip-\(id)", filename: "roundtrip-\(id).bin")
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

// Security regression tests for the encrypted local profile. They run against
// an isolated Keychain service/account and filename, never the app's own item.
final class ProfileStoreSecurityTests: XCTestCase {
    private let service = "org.sidewalks.ParkingReporter.tests"
    private let account = "security-tests-v1"

    private func makeStore() -> ProfileStore {
        ProfileStore(service: service, account: account, filename: "security-tests-v1.bin")
    }
    private var itemQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }
    private func deleteKeyOnly() {
        SecItemDelete(itemQuery as CFDictionary)
    }
    private func keyExists() -> Bool {
        var query = itemQuery
        query[kSecReturnData as String] = true
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    override func setUp() {
        super.setUp()
        let store = makeStore()
        try? store.delete()
    }
    override func tearDown() {
        try? makeStore().delete()
        super.tearDown()
    }

    private func syntheticProfile() -> ReporterProfile {
        ReporterProfile(first: "Synthetic", last: "Only", phone: "000", identifier: "000", email: "test@example.invalid")
    }

    func testCiphertextExcludesPlaintext() throws {
        let store = makeStore()
        let marker = "ZZ-MARKER-\(UUID().uuidString)"
        var profile = syntheticProfile()
        profile.first = marker
        profile.phone = marker
        try store.save(profile)
        let raw = try Data(contentsOf: store.fileURL())
        XCTAssertNil(raw.range(of: Data(marker.utf8)), "plaintext marker leaked into the sealed file")
        XCTAssertEqual(try store.load().first, marker)
    }

    func testTamperRejected() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        let file = try store.fileURL()
        var bytes = try Data(contentsOf: file)
        XCTAssertGreaterThan(bytes.count, 16)
        bytes[bytes.count - 1] ^= 0xFF
        try bytes.write(to: file)
        XCTAssertThrowsError(try store.load(), "tampered ciphertext must not decrypt")
    }

    func testMissingKeyFailsClosedAndIsNotReplaced() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        let file = try store.fileURL()
        let sealed = try Data(contentsOf: file)
        deleteKeyOnly()
        XCTAssertFalse(keyExists())
        XCTAssertThrowsError(try store.load()) { error in
            guard case ProfileError.missingKey = error else {
                return XCTFail("expected missingKey, got \(error)")
            }
        }
        XCTAssertThrowsError(try store.save(syntheticProfile()), "save must not silently create a new key over an existing profile")
        XCTAssertFalse(keyExists(), "a failed save must not create a replacement key")
        XCTAssertEqual(try Data(contentsOf: file), sealed, "the existing ciphertext must be untouched")
    }

    func testCorruptKeyRejected() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        let status = SecItemUpdate(itemQuery as CFDictionary,
                                   [kSecValueData as String: Data(repeating: 0xAB, count: 16)] as CFDictionary)
        XCTAssertEqual(status, errSecSuccess)
        XCTAssertThrowsError(try store.load()) { error in
            guard case ProfileError.corrupt = error else {
                return XCTFail("expected corrupt, got \(error)")
            }
        }
    }

    func testCorruptFileRejected() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        try Data(repeating: 0x41, count: 64).write(to: store.fileURL())
        XCTAssertThrowsError(try store.load(), "garbage bytes must not decode as a profile")
    }

    func testKeychainItemAttributes() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        var query = itemQuery
        query[kSecReturnAttributes as String] = true
        var result: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &result), errSecSuccess)
        let attrs = try XCTUnwrap(result as? [String: Any])
        XCTAssertEqual(attrs[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String,
                       "key must be WhenUnlockedThisDeviceOnly")
        if let sync = attrs[kSecAttrSynchronizable as String] as? Bool {
            XCTAssertFalse(sync, "key must never sync off this device")
        }
    }

    func testFileProtectionAndBackupExclusion() throws {
        let store = makeStore()
        try store.save(syntheticProfile())
        let file = try store.fileURL()
        let values = try file.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true, "profile file must be excluded from backup")
        #if targetEnvironment(simulator)
        // The simulator does not apply data protection classes: the attribute
        // reads back as nil even though save() writes with .completeFileProtection.
        // On-device verification is a release gate listed on PR #2.
        #else
        let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
        XCTAssertEqual(attrs[.protectionKey] as? FileProtectionType, .complete,
                       "profile file must use complete file protection")
        #endif
    }
}

final class ProfileStoreIsolationTests: XCTestCase {
    func testTestNamespacesDifferFromProduction() {
        XCTAssertNotEqual("org.sidewalks.ParkingReporter.tests", ProfileStore.productionService)
        XCTAssertNotEqual("security-tests-v1", ProfileStore.productionAccount)
        XCTAssertNotEqual("security-tests-v1.bin", ProfileStore.productionFilename)
        XCTAssertTrue(ProfileStore.productionService.hasSuffix(".profile"))
    }
}
