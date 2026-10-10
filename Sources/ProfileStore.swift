import Foundation
import CryptoKit
import Security

struct ReporterProfile: Codable, Equatable {
    var first = ""
    var last = ""
    var phone = ""
    var identifier = ""
    var email = ""
}

enum ProfileError: Error { case keychain(OSStatus), corrupt, missingKey }

struct ProfileStore {
    private let service = "org.sidewalks.ParkingReporter.profile"
    private let account = "profile-aes-gcm-v1"
    private var keyQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }
    private func location() throws -> URL {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                             appropriateFor: nil, create: true)
        return dir.appendingPathComponent("reporter-profile-v1.bin")
    }
    private func key(create: Bool) throws -> SymmetricKey {
        var query = keyQuery
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            guard let bytes = result as? Data, bytes.count == 32 else { throw ProfileError.corrupt }
            return SymmetricKey(data: bytes)
        }
        guard status == errSecItemNotFound else { throw ProfileError.keychain(status) }
        guard create else { throw ProfileError.missingKey }
        let key = SymmetricKey(size: .bits256)
        var item = keyQuery
        item[kSecValueData as String] = key.withUnsafeBytes { Data($0) }
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        if added == errSecDuplicateItem { return try self.key(create: false) }
        guard added == errSecSuccess else { throw ProfileError.keychain(added) }
        return key
    }
    private let context = Data("parking-local-profile-v1".utf8)
    func load() throws -> ReporterProfile {
        let file = try location()
        guard FileManager.default.fileExists(atPath: file.path) else { return ReporterProfile() }
        let bytes = try Data(contentsOf: file)
        let plain = try AES.GCM.open(AES.GCM.SealedBox(combined: bytes), using: key(create: false), authenticating: context)
        return try JSONDecoder().decode(ReporterProfile.self, from: plain)
    }
    func save(_ profile: ReporterProfile) throws {
        let file = try location()
        // A missing key must not silently replace a key protecting an existing profile.
        let exists = FileManager.default.fileExists(atPath: file.path)
        let sealed = try AES.GCM.seal(JSONEncoder().encode(profile), using: key(create: !exists), authenticating: context)
        guard let bytes = sealed.combined else { throw ProfileError.corrupt }
        try bytes.write(to: file, options: [.atomic, .completeFileProtection])
        var resource = file
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try resource.setResourceValues(values)
    }
    func delete() throws {
        let file = try location()
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        let status = SecItemDelete(keyQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw ProfileError.keychain(status) }
    }
}
