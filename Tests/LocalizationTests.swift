import XCTest
@testable import ParkingReporter

final class LocalizationTests: XCTestCase {
    private let loc = Localizer.shared

    func testTableLoadsFromBundle() { XCTAssertGreaterThan(loc.table.count, 100) }

    func testEveryKeyHasHebrewAndEnglish() {
        for (key, entry) in loc.table {
            XCTAssertNotNil(entry["he"], "missing he: \(key)")
            XCTAssertNotNil(entry["en"], "missing en: \(key)")
        }
    }
    func testPlaceholdersMatchAcrossLanguages() {
        let pattern = try! NSRegularExpression(pattern: "\\{[a-z_]+\\}")
        func names(_ value: Any?) -> Set<String> {
            let strings: [String]
            if let s = value as? String { strings = [s] } else if let d = value as? [String: String] { strings = Array(d.values) } else { strings = [] }
            return Set(strings.flatMap { s in pattern.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { (s as NSString).substring(with: $0.range) } })
        }
        for (key, entry) in loc.table {
            let en = names(entry["en"])
            for language in ReviewLanguage.allCases where language != .english {
                guard entry[language.rawValue] != nil else { continue }
                XCTAssertTrue(names(entry[language.rawValue]).isSubset(of: en.union(["{count}"])), "placeholder mismatch \(language.rawValue): \(key)")
            }
        }
    }
    func testLookupFallsBackToEnglishThenKey() {
        XCTAssertEqual(loc.string("common.ok", .hebrew), "אישור")
        XCTAssertEqual(loc.string("no.such.key", .english), "no.such.key")
        let custom = Localizer(table: ["k": ["en": "Hello {name}"]])
        XCTAssertEqual(custom.string("k", .russian, ["name": "Dana"]), "Hello Dana")
    }
    func testPluralRules() {
        XCTAssertEqual(PluralRule.category(.hebrew, 2), "two")
        XCTAssertEqual(PluralRule.category(.english, 1), "one")
        XCTAssertEqual(PluralRule.category(.english, 0), "other")
        XCTAssertEqual(PluralRule.category(.amharic, 0), "one")
        XCTAssertEqual(PluralRule.category(.arabic, 0), "zero")
        XCTAssertEqual(PluralRule.category(.arabic, 7), "few")
        XCTAssertEqual(PluralRule.category(.arabic, 11), "many")
        XCTAssertEqual(PluralRule.category(.russian, 21), "one")
        XCTAssertEqual(PluralRule.category(.russian, 3), "few")
        XCTAssertEqual(PluralRule.category(.russian, 12), "many")
    }
    func testPluralStringsRender() {
        XCTAssertEqual(loc.plural("common.reports_count", .english, count: 1), "1 report")
        XCTAssertEqual(loc.plural("common.reports_count", .hebrew, count: 2), "שני דיווחים")
        XCTAssertEqual(loc.plural("common.reports_count", .hebrew, count: 5), "5 דיווחים")
    }
    func testRightToLeftLanguages() {
        XCTAssertEqual(ReviewLanguage.allCases.filter { $0.isRightToLeft }.map { $0.rawValue }.sorted(), ["ar", "he"])
    }
}
