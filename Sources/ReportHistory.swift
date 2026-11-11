import Foundation

enum ReportState: String, Codable, Equatable { case draft, preview }

struct SavedReport: Identifiable, Equatable {
    let id: String
    let category: ReportCategory
    let address: String
    let date: Date
    let state: ReportState
}

// Synthetic examples only. Real history storage comes with the submission milestone.
enum SampleReports {
    static func all() -> [SavedReport] {
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "UTC"),
                                  year: 2026, month: 1, day: 1, hour: 12, minute: 0).date ?? Date(timeIntervalSince1970: 1_767_268_800)
        return [
            SavedReport(id: "s1", category: .sidewalkParking, address: "Example St 12", date: base, state: .draft),
            SavedReport(id: "s2", category: .brokenSign, address: "Sample Ave 5", date: base.addingTimeInterval(-86_400), state: .preview),
            SavedReport(id: "s3", category: .fadedCrosswalk, address: "Test Rd 31", date: base.addingTimeInterval(-172_800), state: .preview),
        ]
    }
    static func grouped(_ items: [SavedReport]) -> (drafts: [SavedReport], others: [SavedReport]) {
        let sorted = items.sorted { $0.date > $1.date }
        return (sorted.filter { $0.state == .draft }, sorted.filter { $0.state != .draft })
    }
}
