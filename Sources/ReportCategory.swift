import Foundation

enum ReportCategory: String, CaseIterable, Codable, Identifiable {
    case unknown, sidewalkParking, brokenSign, fadedCrosswalk
    var id: String { rawValue }
    var requiresPlate: Bool { self == .sidewalkParking }
    func title(_ language: ReviewLanguage) -> String {
        switch self {
        case .unknown: return language.text("טרם זוהה", "Not identified yet")
        case .sidewalkParking: return language.text("רכב על המדרכה", "Vehicle on sidewalk")
        case .brokenSign: return language.text("תמרור שבור", "Broken traffic sign")
        case .fadedCrosswalk: return language.text("מעבר חציה דהוי", "Faded crosswalk")
        }
    }
}
struct CategoryReviewDraft: Equatable, Codable {
    private(set) var category: ReportCategory = .unknown
    private(set) var plate: String?
    var location = ""
    var confirmedTime = ""
    var description = ""
    mutating func select(_ category: ReportCategory) {
        self.category = category
        if !category.requiresPlate { plate = nil }
    }
    // Automatic classifier suggestions must use the same category/field transition.
    mutating func suggest(_ category: ReportCategory) { select(category) }
    mutating func correctPlate(_ value: String) { plate = category.requiresPlate ? value : nil }
}
