import Foundation
import SwiftUI

// Language choice and first-run state. Stored in UserDefaults, nothing sensitive.
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults
    @Published var savedLanguage: ReviewLanguage? { didSet { defaults.set(savedLanguage?.rawValue, forKey: Keys.language) } }
    @Published var onboarded: Bool { didSet { defaults.set(onboarded, forKey: Keys.onboarded) } }
    // Not persisted: lets a preview launch with --preview-onboarding finish the flow.
    @Published var finishedThisSession = false
    enum Keys { static let language = "app.language"; static let onboarded = "app.onboarded" }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        savedLanguage = defaults.string(forKey: Keys.language).flatMap(ReviewLanguage.init(rawValue:))
        onboarded = defaults.bool(forKey: Keys.onboarded)
    }
    func language(arguments: [String], preferred: [String]) -> ReviewLanguage {
        ReviewLanguage.resolve(arguments: arguments, preferred: preferred, saved: savedLanguage)
    }
    // Preview and test launches skip first-run unless they ask for it.
    func shouldShowOnboarding(arguments: [String]) -> Bool {
        if arguments.contains("--preview-onboarding") { return !finishedThisSession }
        if arguments.contains(where: { $0.hasPrefix("--preview-") }) { return false }
        return !onboarded
    }
}

enum ReporterValidation {
    static func validName(_ value: String) -> Bool { !value.trimmingCharacters(in: .whitespaces).isEmpty }
    // Israeli mobile (05x-xxxxxxx, also as +9725xxxxxxxx) or an international number with + and
    // country code. Landlines and all-zero numbers are rejected, matching the user-facing hint.
    static func validPhone(_ value: String) -> Bool {
        let compact = value.filter { !" -()".contains($0) }
        guard compact.allSatisfy({ $0 == "+" || ("0"..."9").contains($0) }), compact.filter({ $0 == "+" }).count <= 1 else { return false }
        if compact.hasPrefix("+") {
            let digits = String(compact.dropFirst())
            guard !digits.isEmpty, !digits.hasPrefix("0"), (7...15).contains(digits.count) else { return false }
            if digits.hasPrefix("972") { return digits.count == 12 && digits.dropFirst(3).hasPrefix("5") }
            return true
        }
        return compact.count == 10 && compact.hasPrefix("05") && Set(compact.dropFirst(2)).count > 1
    }
    // Five to nine ASCII digits with the Israeli check digit. ASCII only: other scripts' digits
    // pass Character.isNumber but must never reach Int conversion.
    static func validID(_ value: String) -> Bool {
        let digits = Array(value.utf8)
        guard (5...9).contains(digits.count), digits.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return false }
        let padded = [UInt8](repeating: 48, count: 9 - digits.count) + digits
        var sum = 0
        for (index, byte) in padded.enumerated() {
            var n = Int(byte - 48) * (index % 2 == 0 ? 1 : 2)
            if n > 9 { n -= 9 }
            sum += n
        }
        return sum % 10 == 0 && sum > 0
    }
    static func validEmail(_ value: String) -> Bool {
        value.isEmpty || value.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) != nil
    }
}
