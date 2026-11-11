import SwiftUI

struct RootTabView: View {
    @StateObject private var settings = AppSettings()
    private let arguments: [String]
    @State private var tab: Int
    private var language: ReviewLanguage { settings.language(arguments: arguments, preferred: Locale.preferredLanguages) }
    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.arguments = arguments
        _tab = State(initialValue: arguments.contains("--preview-history") ? 1 : arguments.contains("--preview-settings") ? 2 : 0)
    }
    var body: some View {
        Group {
            if settings.shouldShowOnboarding(arguments: arguments) {
                OnboardingView(settings: settings, language: language) { settings.onboarded = true }
            } else { tabs }
        }
        .accentColor(AppTheme.accent)
        .environment(\.layoutDirection, language.direction)
    }
    private var tabs: some View {
        TabView(selection: $tab) {
            ContentView(language: language).id(language)
                .tabItem { Label(language.text("דיווח", "Report"), systemImage: "camera.fill") }.tag(0)
            HistoryView(language: language)
                .tabItem { Label(language.text("הדיווחים שלי", "My reports"), systemImage: "list.bullet.rectangle") }.tag(1)
            SettingsView(language: language, settings: settings)
                .tabItem { Label(language.text("הגדרות", "Settings"), systemImage: "gearshape") }.tag(2)
        }
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
            Text(report.address(language)).font(.subheadline).foregroundColor(.secondary)
            Text(ReportTimeFormat.string(from: report.date, timeZone: TimeZone(identifier: "UTC") ?? .current))
                .font(.caption).foregroundColor(.secondary).environment(\.layoutDirection, .leftToRight)
        }.padding(.vertical, 4)
    }
}

struct LanguageListView: View {
    @ObservedObject var settings: AppSettings
    let language: ReviewLanguage
    var body: some View {
        List {
            Button { settings.savedLanguage = nil } label: {
                HStack { Text(Localizer.shared.string("settings.language.system_default", language)); Spacer()
                    if settings.savedLanguage == nil { Image(systemName: "checkmark") } }
            }
            ForEach(ReviewLanguage.allCases) { item in
                Button { settings.savedLanguage = item } label: {
                    HStack { Text(item.nativeName); Spacer()
                        if settings.savedLanguage == item { Image(systemName: "checkmark") } }
                }
            }
        }.foregroundColor(.primary)
        .navigationTitle(Localizer.shared.string("settings.language.title", language)).navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    let language: ReviewLanguage
    @ObservedObject var settings: AppSettings
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: LanguageListView(settings: settings, language: language)) {
                        Label(Localizer.shared.string("settings.language.title", language), systemImage: "globe")
                    }
                }
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
