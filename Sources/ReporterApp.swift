import SwiftUI
import Vision
import AVFoundation

@main struct ReporterApp: App {
    var body: some Scene { WindowGroup {
        if ProcessInfo.processInfo.arguments.contains("--preview-profile") {
            let language: ReviewLanguage = ProcessInfo.processInfo.arguments.contains("--preview-he") ? .hebrew : .english
            NavigationView { ProfileView(language: language) }.environment(\.layoutDirection, language.direction)
        } else { ContentView() }
    } }
}
struct ContentView: View {
    private let language: ReviewLanguage
    @State private var image: UIImage?
    @State private var recognition: PlateRecognition
    @State private var plate: String
    @State private var status = ""
    @State private var picker: PickerKind?
    @State private var busy = false
    @State private var editing: Bool
    @State private var revision = UUID()
    @State private var privacy = false
    @State private var showProfile = false
    private let accent = Color(red: 0.07, green: 0.40, blue: 0.42)
    enum PickerKind: String, Identifiable { case camera, library; var id: String { rawValue } }
    init() {
        let args = ProcessInfo.processInfo.arguments
        language = args.contains("--preview-en") ? .english : (Locale.preferredLanguages.first?.hasPrefix("he") == true || args.contains("--preview-he") ? .hebrew : .english)
        let demo = args.contains("--preview-he") || args.contains("--preview-en")
        let uncertain = args.contains("--preview-uncertain")
        _image = State(initialValue: demo ? ReviewPreview.image() : nil)
        _recognition = State(initialValue: PlateRecognition(candidates: demo && !uncertain ? ["1234567"] : [], confidence: demo && !uncertain ? 0.99 : 0))
        _plate = State(initialValue: demo && !uncertain ? "1234567" : "")
        _editing = State(initialValue: demo && uncertain)
    }
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label(language.text("תצוגת פיתוח", "Development preview"), systemImage: "hammer.fill")
                            .font(.caption.weight(.semibold)).foregroundColor(accent)
                        Spacer()
                        Button { privacy = true } label: { Image(systemName: "lock.shield").frame(width: 44, height: 44) }
                            .accessibilityLabel(language.text("פרטיות", "Privacy"))
                    }
                    VStack(spacing: 0) {
                        if let image = image {
                            Image(uiImage: image).resizable().scaledToFill().frame(height: 188).clipped()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.viewfinder").font(.system(size: 42, weight: .light)).foregroundColor(accent)
                                Text(language.text("מתחילים בתמונה", "Start with a photo")).font(.headline)
                                Text(language.text("הזיהוי נעשה במכשיר בלבד", "Text recognition stays on your device")).font(.subheadline).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity).frame(height: 188)
                        }
                        HStack(spacing: 12) {
                            Button { requestCamera() } label: { Label(language.text("צילום", "Camera"), systemImage: "camera.fill").frame(maxWidth: .infinity).frame(minHeight: 48) }
                                .buttonStyle(.plain).foregroundColor(.white).background(accent).cornerRadius(12)
                            Button { picker = .library } label: { Label(language.text("בחירת תמונה", "Choose photo"), systemImage: "photo").frame(maxWidth: .infinity).frame(minHeight: 48) }
                                .buttonStyle(.plain).foregroundColor(accent).background(accent.opacity(0.08)).cornerRadius(12)
                        }.padding(12).disabled(busy)
                    }.background(Color(.secondarySystemGroupedBackground)).cornerRadius(18)
                    if image != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: editing ? "exclamationmark.viewfinder" : "checkmark.viewfinder").foregroundColor(editing ? .orange : accent)
                                Text(language.text("לוחית", "Plate")).font(.subheadline.weight(.medium))
                                if editing {
                                    TextField(language.text("מספר לוחית", "Plate number"), text: $plate).keyboardType(.numberPad).font(.system(.title3, design: .monospaced)).environment(\.layoutDirection, .leftToRight)
                                } else {
                                    Text(plate).font(.system(.title3, design: .monospaced).weight(.semibold)).environment(\.layoutDirection, .leftToRight)
                                }
                                Spacer(minLength: 0)
                                if !editing { Button { editing = true } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel(language.text("עריכת לוחית", "Edit plate")) }
                            }.frame(minHeight: 48)
                            if editing { Text(language.text("הזיהוי לא בטוח. בדקו מול התמונה.", "Recognition is uncertain. Check the photo.")).font(.caption).foregroundColor(.secondary) }
                            if recognition.candidates.count > 1 { ForEach(recognition.candidates, id: \.self) { value in Button(value) { plate = value }.frame(minHeight: 44) } }
                        }.padding(.horizontal, 14).padding(.vertical, 6).background(Color(.secondarySystemGroupedBackground)).cornerRadius(14)
                    }
                    if busy { ProgressView(language.text("מזהה טקסט במכשיר...", "Reading text locally...")) }
                    if !status.isEmpty { Text(status).font(.footnote).foregroundColor(.secondary) }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(language.text("לפני דיווח", "Before reporting")).font(.headline)
                        Text(language.text("בדקו את הלוחית והתמונה. זיהוי אינו הוכחה לעבירה.", "Check the plate and photo. Recognition is not proof of an offence.")).font(.subheadline).foregroundColor(.secondary)
                        Label(language.text("אין שליחת דיווח בגרסה זו", "No report submission in this version"), systemImage: "lock.fill").font(.footnote.weight(.medium)).foregroundColor(accent)
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(accent.opacity(0.06)).cornerRadius(14)
                    Button { showProfile = true } label: {
                        HStack { Label(language.text("פרטי מדווח", "Reporter profile"), systemImage: "person.crop.circle"); Spacer(); Image(systemName: language == .hebrew ? "chevron.left" : "chevron.right") }.frame(minHeight: 48).padding(.horizontal, 14)
                    }.buttonStyle(.plain).background(Color(.secondarySystemGroupedBackground)).cornerRadius(14)
                    Text(language.text("התמונה והזיהוי נשארים במכשיר. הפרופיל מוצפן מקומית.", "Photo and recognition stay on-device. Profile is encrypted locally.")).font(.caption).foregroundColor(.secondary)
                }.padding(16)
            }.background(Color(.systemGroupedBackground))
            .navigationTitle(language.text("דיווח חניה", "Parking Reporter")).navigationBarTitleDisplayMode(.inline)
            .sheet(item: $picker) { selected in if selected == .camera { CameraPicker(receive: accept) } else { PhotoPicker(receive: accept) } }
            .sheet(isPresented: $showProfile) { NavigationView { ProfileView(language: language) } .environment(\.layoutDirection, language.direction) }
            .sheet(isPresented: $privacy) { NavigationView { ScrollView { Text(language.text("תמונות וזיהוי טקסט נשארים במכשיר. שום דיווח לא נשלח. אין SDK אנליטיקה. הפרופיל מוצפן במפתח Keychain למכשיר זה בלבד. התמונות אינן נשמרות אחרי סגירת גרסת הפיתוח.", "Photos and text recognition stay on this device. Nothing is submitted. No analytics SDK. The profile is encrypted with a device-only Keychain key. Photos are not saved after closing the preview.")).padding() }.navigationTitle(language.text("פרטיות", "Privacy")) } }
        }.navigationViewStyle(.stack).accentColor(accent).environment(\.layoutDirection, language.direction)
    }
    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { status = language.text("המצלמה אינה זמינה.", "Camera unavailable."); return }
        AVCaptureDevice.requestAccess(for: .video) { granted in DispatchQueue.main.async {
            if granted { picker = .camera } else { status = language.text("אין הרשאת מצלמה. אפשר לבחור תמונה.", "Camera permission denied. Choose a photo instead.") }
        } }
    }
    private func accept(_ photo: UIImage?) {
        picker = nil
        guard let photo = photo else { return }
        image = photo; plate = ""; recognition = PlateRecognition(candidates: [], confidence: 0); status = ""; busy = true
        let token = UUID(); revision = token
        // Re-render orientation and bound work on older phones. Original review image stays untouched in RAM.
        DispatchQueue.global(qos: .userInitiated).async {
            let maxSide: CGFloat = 2000
            let ratio = min(1, maxSide / max(photo.size.width, photo.size.height))
            let size = CGSize(width: max(1, photo.size.width * ratio), height: max(1, photo.size.height * ratio))
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in photo.draw(in: CGRect(origin: .zero, size: size)) }
            var found = PlateRecognition(candidates: [], confidence: 0); var message = "No candidates. Enter the plate manually."
            do {
                guard let cg = normalized.cgImage else { throw ProfileError.corrupt }
                let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false; request.recognitionLanguages = ["en-US"]
                try VNImageRequestHandler(cgImage: cg).perform([request])
                found = PlateRecognition.from((request.results ?? []).compactMap { item in item.topCandidates(1).first.map { ($0.string, $0.confidence) } })
                if !found.candidates.isEmpty { message = "Choose a candidate and verify it against the photo." }
            } catch { message = "Text recognition failed. Enter the plate manually." }
            DispatchQueue.main.async { guard revision == token else { return }; recognition = found; plate = found.candidates.count == 1 ? found.candidates[0] : ""; editing = found.needsCorrection; status = found.candidates.isEmpty ? language.text("לא זוהתה לוחית. הקלידו ידנית.", "No plate found. Enter it manually.") : ""; busy = false }
        }
    }
}
struct ProfileView: View {
    var language: ReviewLanguage = .english
    @State private var profile = ReporterProfile()
    @State private var status = ""
    @State private var canSave = false
    private let store = ProfileStore()
    var body: some View {
        Form {
            Text(language.text("הפרופיל מוצפן ונשמר רק במכשיר זה, ללא סנכרון. למחיקה מלאה השתמשו בכפתור המחיקה.", "Encrypted on this device only, not synced. Use Delete to remove both the profile and its Keychain key."))
            TextField(language.text("שם פרטי", "First name"), text: $profile.first)
            TextField(language.text("שם משפחה", "Last name"), text: $profile.last)
            TextField(language.text("טלפון", "Phone"), text: $profile.phone).keyboardType(.phonePad)
            TextField(language.text("תעודת זהות", "ID"), text: $profile.identifier).keyboardType(.numberPad)
            TextField(language.text("דוא״ל", "Email"), text: $profile.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
            Button(language.text("שמירה במכשיר", "Save locally")) { do { try store.save(profile); status = "Saved on this device." } catch { status = "Could not save. No profile was sent." } }.disabled(!canSave)
            Button(language.text("מחיקת הפרופיל", "Delete local profile"), role: .destructive) { do { try store.delete(); profile = ReporterProfile(); canSave = true; status = "Deleted." } catch { status = "Could not delete the profile." } }
            Text(status)
        }.navigationTitle(language.text("פרטי מדווח", "Reporter profile")).onAppear {
            do { profile = try store.load(); canSave = true } catch { canSave = false; status = "Could not unlock the saved profile. It was not replaced. Unlock this phone and retry, or explicitly delete it." }
        }
    }
}
