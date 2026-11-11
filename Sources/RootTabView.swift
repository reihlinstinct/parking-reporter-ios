import SwiftUI

struct RootTabView: View {
    let language: ReviewLanguage
    @State private var tab: Int
    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        language = ReviewLanguage.resolve(arguments: arguments, preferred: Locale.preferredLanguages)
        _tab = State(initialValue: arguments.contains("--preview-history") ? 1 : arguments.contains("--preview-settings") ? 2 : 0)
    }
    var body: some View {
        TabView(selection: $tab) {
            ContentView()
                .tabItem { Label(language.text("דיווח", "Report"), systemImage: "camera.fill") }.tag(0)
            HistoryView(language: language)
                .tabItem { Label(language.text("הדיווחים שלי", "My reports"), systemImage: "list.bullet.rectangle") }.tag(1)
            SettingsView(language: language)
                .tabItem { Label(language.text("הגדרות", "Settings"), systemImage: "gearshape") }.tag(2)
        }
        .accentColor(AppTheme.accent)
        .environment(\.layoutDirection, language.direction)
    }
}

struct HistoryView: View {
    let language: ReviewLanguage
    var items: [SavedReport] = SampleReports.all()
    var body: some View {
        NavigationView {
            Group {
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
                        Text(language.text("אין דיווחים עדיין", "No reports yet")).font(.headline)
                    }
                } else {
                    let groups = SampleReports.grouped(items)
                    List {
                        if !groups.drafts.isEmpty {
                            Section(header: Text(language.text("טיוטות", "Drafts"))) { ForEach(groups.drafts) { row($0) } }
                        }
                        if !groups.others.isEmpty {
                            Section(header: Text(language.text("דוגמאות", "Examples"))) { ForEach(groups.others) { row($0) } }
                        }
                    }.listStyle(.insetGrouped)
                }
            }
            .navigationTitle(language.text("הדיווחים שלי", "My reports"))
        }.navigationViewStyle(.stack)
    }
    private func row(_ report: SavedReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.category.title(language)).font(.headline)
            Text(report.address).font(.subheadline).foregroundColor(.secondary)
            Text(ReportTimeFormat.string(from: report.date, timeZone: TimeZone(identifier: "UTC") ?? .current))
                .font(.caption).foregroundColor(.secondary).environment(\.layoutDirection, .leftToRight)
        }.padding(.vertical, 4)
    }
}

struct SettingsView: View {
    let language: ReviewLanguage
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: ProfileView(language: language)) {
                        Label(language.text("פרטי המדווח", "Reporter details"), systemImage: "person.crop.circle")
                    }
                }
                Section(header: Text(language.text("מידע", "About"))) {
                    NavigationLink(destination: PrivacyView(language: language)) {
                        Label(language.text("פרטיות", "Privacy"), systemImage: "lock.shield")
                    }
                    Text(language.text("אין שליחת דיווחים בגרסה זו.", "Reports are not submitted in this version."))
                        .font(.footnote).foregroundColor(.secondary)
                }
            }.navigationTitle(language.text("הגדרות", "Settings"))
        }.navigationViewStyle(.stack)
    }
}

struct PrivacyView: View {
    let language: ReviewLanguage
    var body: some View {
        ScrollView {
            Text(language.text("תמונות וזיהוי טקסט נשארים במכשיר. שום דיווח לא נשלח. אין SDK אנליטיקה. הפרופיל מוצפן במפתח Keychain למכשיר זה בלבד.", "Photos and text recognition stay on this device. Nothing is submitted. No analytics SDK. Profile uses a device-only Keychain key.")).padding()
        }.navigationTitle(language.text("פרטיות", "Privacy")).navigationBarTitleDisplayMode(.inline)
    }
}
