import Foundation

private final class BundleToken {}

// Reads the shared five-language string table (copied from the Android app's i18n/strings.json).
// Lookup falls back to English, then to the key itself, so a gap is visible and never a crash.
struct Localizer {
    typealias Table = [String: [String: Any]]
    let table: Table
    private let uiTable: [String: [String: String]]

    static let shared = Localizer(bundle: Bundle(for: BundleToken.self))

    init(table: Table, ui: [String: [String: String]] = [:]) { self.table = table; self.uiTable = ui }
    func ui(_ english: String, _ language: ReviewLanguage) -> String? { uiTable[english]?[language.rawValue] }
    init(bundle: Bundle) {
        if let url = bundle.url(forResource: "ui_strings", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
           let strings = root["strings"] as? [String: [String: String]] { uiTable = strings } else { uiTable = [:] }
        guard let url = bundle.url(forResource: "strings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let strings = root["strings"] as? Table else { self.table = [:]; return }
        self.table = strings
    }

    func string(_ key: String, _ language: ReviewLanguage, _ args: [String: String] = [:]) -> String {
        guard let entry = table[key] else { return key }
        let value = entry[language.rawValue] ?? entry["en"]
        guard let text = value as? String else { return key }
        return Localizer.fill(text, args)
    }

    func plural(_ key: String, _ language: ReviewLanguage, count: Int) -> String {
        guard let entry = table[key] else { return key }
        let forms = (entry[language.rawValue] ?? entry["en"]) as? [String: String] ?? [:]
        let category = PluralRule.category(language, count)
        let text = forms[category] ?? forms["other"] ?? key
        return Localizer.fill(text, ["count": String(count)])
    }

    static func fill(_ text: String, _ args: [String: String]) -> String {
        args.reduce(text) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
    }
}

enum PluralRule {
    static func category(_ language: ReviewLanguage, _ n: Int) -> String {
        switch language {
        case .hebrew: return n == 1 ? "one" : n == 2 ? "two" : "other"
        case .english: return n == 1 ? "one" : "other"
        case .amharic, .french: return n == 0 || n == 1 ? "one" : "other"
        case .arabic:
            if n == 0 { return "zero" }; if n == 1 { return "one" }; if n == 2 { return "two" }
            let r = n % 100
            return r >= 3 && r <= 10 ? "few" : r >= 11 ? "many" : "other"
        case .russian:
            let m10 = n % 10, m100 = n % 100
            if m10 == 1 && m100 != 11 { return "one" }
            if m10 >= 2 && m10 <= 4 && !(m100 >= 12 && m100 <= 14) { return "few" }
            return "many"
        }
    }
}
