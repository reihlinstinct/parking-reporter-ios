import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    let language: ReviewLanguage
    var finish: () -> Void
    @State private var step = 0
    @State private var profile = ReporterProfile()
    @State private var attempted = false
    @State private var saveFailed = false
    private let store = ProfileStore()
    private func t(_ key: String) -> String { Localizer.shared.string(key, language) }

    var body: some View {
        NavigationView {
            Group { if step == 0 { welcome } else { setup } }
                .navigationBarTitleDisplayMode(.inline)
        }.navigationViewStyle(.stack).accentColor(AppTheme.accent)
    }
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Image(systemName: "figure.walk.diamond").font(.system(size: 60, weight: .light)).foregroundColor(AppTheme.accent)
            Text(t("firstrun.title")).font(.largeTitle.weight(.bold))
            Text(t("firstrun.intro")).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text(t("firstrun.step_capture")); Text(t("firstrun.step_review")); Text(t("firstrun.step_send"))
            }.font(.body)
            Text(t("firstrun.settings_note")).font(.footnote).foregroundColor(.secondary)
            Spacer()
            Button { step = 1 } label: { Text(t("firstrun.start")).font(.headline).frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large)
        }.padding(24)
    }
    private var setup: some View {
        Form {
            Section(footer: Text(t("setup.description"))) {
                Picker(t("settings.language.title"), selection: Binding(get: { language }, set: { settings.savedLanguage = $0 })) {
                    ForEach(ReviewLanguage.allCases) { Text($0.nativeName).tag($0) }
                }
            }
            Section {
                field("settings.field.first_name", $profile.first, valid: ReporterValidation.validName(profile.first), error: nil)
                field("settings.field.last_name", $profile.last, valid: ReporterValidation.validName(profile.last), error: nil)
                field("settings.field.phone", $profile.phone, valid: ReporterValidation.validPhone(profile.phone), error: "settings.phone.invalid", keyboard: .phonePad)
                field("settings.field.id_number", $profile.identifier, valid: ReporterValidation.validID(profile.identifier), error: "settings.id.invalid", keyboard: .numberPad)
                field("settings.field.email", $profile.email, valid: ReporterValidation.validEmail(profile.email), error: "settings.email.invalid", keyboard: .emailAddress)
            }
            Section {
                Button(t("setup.save_continue")) { save() }.accessibilityIdentifier("onboarding.save")
                Button(t("setup.later")) { finish() }.foregroundColor(.secondary).accessibilityIdentifier("onboarding.later")
                if saveFailed { Text(t("common.error.generic")).foregroundColor(.red) }
            }
        }.navigationTitle(t("setup.title"))
    }
    private func field(_ key: String, _ binding: Binding<String>, valid: Bool, error: String?, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(t(key), text: binding).keyboardType(keyboard).disableAutocorrection(true).textContentType(nil)
            if attempted && !valid { Text(error.map(t) ?? t("common.error.generic")).font(.caption).foregroundColor(.red) }
        }
    }
    private func save() {
        attempted = true
        guard ReporterValidation.validName(profile.first), ReporterValidation.validName(profile.last),
              ReporterValidation.validPhone(profile.phone), ReporterValidation.validID(profile.identifier),
              ReporterValidation.validEmail(profile.email) else { return }
        do { try store.save(profile); finish() } catch { saveFailed = true }
    }
}
