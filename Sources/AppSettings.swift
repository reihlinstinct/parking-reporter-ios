import Foundation
import SwiftUI

// Language choice and first-run state. Stored in UserDefaults, nothing sensitive.
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults
    @Published var savedLanguage: ReviewLanguage? { didSet { defaults.set(savedLanguage?.rawValue, forKey: Keys.language) } }
    @Published var onboarded: Bool { didSet { defaults.set(onboarded, forKey: Keys.onboarded) } }
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
        if arguments.contains("--preview-onboarding") { return true }
        if arguments.contains(where: { $0.hasPrefix("--preview-") }) { return false }
        return !onboarded
    }
}

enum ReporterValidation {
    static func validName(_ value: String) -> Bool { !value.trimmingCharacters(in: .whitespaces).isEmpty }
    // Israeli mobile or landline, local or +972 form.
    static func validPhone(_ value: String) -> Bool {
        var digits = value.filter { $0.isNumber }
        if value.hasPrefix("+972") { digits = "0" + digits.dropFirst(3) }
        return digits.hasPrefix("0") && (9...10).contains(digits.count)
    }
    // Nine digits with the Israeli check digit.
    static func validID(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        guard digits.count == value.count, (5...9).contains(digits.count) else { return false }
        let padded = String(repeating: "0", count: 9 - digits.count) + digits
        let sum = padded.enumerated().reduce(0) { acc, item in
            var n = Int(String(item.element))! * (item.offset % 2 == 0 ? 1 : 2)
            if n > 9 { n -= 9 }
            return acc + n
        }
        return sum % 10 == 0
    }
    static func validEmail(_ value: String) -> Bool {
        value.isEmpty || value.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) != nil
    }
}
