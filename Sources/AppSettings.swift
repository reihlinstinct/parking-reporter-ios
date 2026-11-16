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
    /// Any decimal digit (Arabic-Indic, Devanagari, fullwidth...) becomes ASCII 0-9, like Android's
    /// ReporterInput.digits. Everything else is dropped.
    static func digits(_ value: String) -> String {
        var out = ""
        for scalar in value.unicodeScalars where scalar.properties.generalCategory == .decimalNumber {
            if let n = Character(scalar).wholeNumberValue, (0...9).contains(n) { out.append(Character(String(n))) }
        }
        return out
    }
    static func phoneInput(_ value: String) -> String {
        (value.trimmingCharacters(in: .whitespaces).hasPrefix("+") ? "+" : "") + digits(value)
    }
    /// 05x-xxxxxxx becomes +9725xxxxxxxx; everything else is returned in normalized form.
    static func canonicalPhone(_ value: String) -> String {
        let clean = phoneInput(value)
        if clean.count == 10, clean.hasPrefix("05") { return "+972" + clean.dropFirst() }
        return clean
    }
    static func canonicalID(_ value: String) -> String { digits(value) }
    // Israeli mobile (05x-xxxxxxx or +9725xxxxxxxx) or an international number: + and 8 to 15
    // digits, no leading 0. Landlines, +972 non-mobile and all-zero numbers are rejected.
    static func validPhone(_ value: String) -> Bool {
        let canonical = canonicalPhone(value)
        guard canonical.hasPrefix("+") else { return false }
        let digits = String(canonical.dropFirst())
        guard (8...15).contains(digits.count), !digits.hasPrefix("0") else { return false }
        if digits.hasPrefix("972") { return digits.count == 12 && digits.dropFirst(3).hasPrefix("5") && Set(digits.dropFirst(4)).count > 1 }
        return true
    }
    // One to nine digits (padded with zeros) with the Israeli check digit, after digit normalizing.
    static func validID(_ value: String) -> Bool {
        let ascii = Array(canonicalID(value).utf8)
        guard (1...9).contains(ascii.count) else { return false }
        let padded = [UInt8](repeating: 48, count: 9 - ascii.count) + ascii
        var sum = 0
        for (index, byte) in padded.enumerated() {
            var n = Int(byte - 48) * (index % 2 == 0 ? 1 : 2)
            if n > 9 { n -= 9 }
            sum += n
        }
        return sum % 10 == 0 && sum > 0
    }
    static func normalized(_ profile: ReporterProfile) -> ReporterProfile {
        var p = profile
        p.phone = canonicalPhone(p.phone); p.identifier = canonicalID(p.identifier)
        p.first = p.first.trimmingCharacters(in: .whitespaces); p.last = p.last.trimmingCharacters(in: .whitespaces)
        p.email = p.email.trimmingCharacters(in: .whitespaces)
        return p
    }
    static func validEmail(_ value: String) -> Bool {
        value.isEmpty || value.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) != nil
    }
}
