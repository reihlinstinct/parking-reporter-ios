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
    @State private var review = false
    @State private var category: ReportCategory = .unknown
    @State private var draft = CategoryReviewDraft()
    @State private var location = ""
    @State private var reportTime = ""
    @State private var detailEditor: DetailField?
    enum DetailField: String, Identifiable { case category, location, time; var id: String { rawValue } }
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
        _review = State(initialValue: demo && !args.contains("--preview-capture"))
        let category: ReportCategory = args.contains("--preview-sign") ? .brokenSign : args.contains("--preview-crosswalk") ? .fadedCrosswalk : demo ? .sidewalkParking : .unknown
        _category = State(initialValue: category)
    }
    var body: some View {
        NavigationView {
            Group {
                if review { reviewPage } else { capturePage }
            }
            .navigationTitle(language.text(review ? "בדיקת דיווח" : "דיווח חניה", review ? "Review report" : "Parking Reporter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showProfile = true } label: { Image(systemName: "gearshape").frame(width: 44, height: 44) }.accessibilityLabel(language.text("הגדרות", "Settings"))
                }
            }
            .sheet(item: $picker) { selected in if selected == .camera { CameraPicker(receive: accept) } else { PhotoPicker(receive: accept) } }
            .sheet(isPresented: $showProfile) { NavigationView { ProfileView(language: language) }.environment(\.layoutDirection, language.direction) }
            .sheet(isPresented: $privacy) { NavigationView { ScrollView { Text(language.text("תמונות וזיהוי טקסט נשארים במכשיר. שום דיווח לא נשלח. אין SDK אנליטיקה. הפרופיל מוצפן במפתח Keychain למכשיר זה בלבד.", "Photos and text recognition stay on this device. Nothing is submitted. No analytics SDK. Profile uses a device-only Keychain key.")).padding() }.navigationTitle(language.text("פרטיות", "Privacy")) } }
            .sheet(item: $detailEditor) { field in
                NavigationView {
                    Form {
                        if field == .category {
                            Picker(language.text("סוג דיווח", "Category"), selection: $category) {
                                ForEach(ReportCategory.allCases) { value in Text(value.title(language)).tag(value) }
                            }
                        }
                        if field == .location { TextField(language.text("מיקום", "Location"), text: $location) }
                        if field == .time { TextField(language.text("מועד הצילום", "Photo time"), text: $reportTime) }
                    }.navigationTitle(language.text("עריכת פרט", "Edit detail")).toolbar { Button(language.text("סיום", "Done")) { detailEditor = nil } }
                }.environment(\.layoutDirection, language.direction)
            }
        }.navigationViewStyle(.stack).accentColor(accent).environment(\.layoutDirection, language.direction)
        .onChange(of: category) { value in
            draft.select(value)
            if !value.requiresPlate { plate = ""; editing = false }
            else { editing = plate.isEmpty || recognition.needsCorrection }
        }
        .onChange(of: plate) { draft.correctPlate($0) }
        .onChange(of: location) { draft.location = $0 }
        .onChange(of: reportTime) { draft.confirmedTime = $0 }
    }
    private var capturePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.viewfinder").font(.system(size: 68, weight: .light)).foregroundColor(accent)
            VStack(spacing: 8) {
                Text(language.text("צלמו את המפגע", "Photograph the issue")).font(.title2.weight(.bold))
                Text(language.text("התמונה תנותח אוטומטית ותועבר לבדיקה", "The photo is analyzed automatically, then opens for review")).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            if busy { ProgressView(language.text("מנתח במכשיר...", "Analyzing on-device...")) }
            Button { requestCamera() } label: { Label(language.text("צילום תמונה", "Take photo"), systemImage: "camera.fill").font(.headline).frame(maxWidth: .infinity).frame(height: 56) }.foregroundColor(.white).background(accent).cornerRadius(16).disabled(busy)
            Button(language.text("או בחרו תמונה קיימת", "Or choose an existing photo")) { picker = .library }.frame(minHeight: 44).disabled(busy)
            if !status.isEmpty { Text(status).font(.footnote).foregroundColor(.secondary) }
            Spacer()
            Text(language.text("ניתוח מקומי בלבד • אין שליחה בגרסת הפיתוח", "Local analysis only • No submission in this preview")).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(24).background(Color(.systemGroupedBackground))
    }
    private var reviewPage: some View {
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
                    }.background(Color(.secondarySystemGroupedBackground)).cornerRadius(18)
                    if image != nil && category.requiresPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: editing ? "exclamationmark.triangle.fill" : "checkmark.circle.fill").foregroundColor(editing ? .orange : accent)
                                Text(language.text("לוחית", "Plate")).font(.subheadline.weight(.medium))
                                if editing {
                                    TextField(language.text("מספר לוחית", "Plate number"), text: $plate).keyboardType(.numberPad).font(.title3).environment(\.layoutDirection, .leftToRight)
                                } else {
                                    Text(plate).font(.system(.title3, design: .monospaced).weight(.semibold)).environment(\.layoutDirection, .leftToRight)
                                }
                                Spacer(minLength: 0)
                                if !editing { Button { editing = true } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel(language.text("עריכת לוחית", "Edit plate")) }
                            }.frame(minHeight: 48)
                            if editing { Text(language.text("הזיהוי לא בטוח. בדקו מול התמונה.", "Recognition is uncertain. Check the photo.")).font(.caption).foregroundColor(Color(.secondaryLabel)) }
                            if recognition.candidates.count > 1 { ForEach(recognition.candidates, id: \.self) { value in Button(value) { plate = value }.frame(minHeight: 44) } }
                        }.padding(.horizontal, 14).padding(.vertical, 6).background(Color(.secondarySystemGroupedBackground)).cornerRadius(14)
                    }
                    if busy { ProgressView(language.text("מזהה טקסט במכשיר...", "Reading text locally...")) }
                    if !status.isEmpty { Text(status).font(.footnote).foregroundColor(.secondary) }
                    VStack(spacing: 0) {
                        detailRow(language.text("סוג דיווח", "Category"), value: category == .unknown ? "" : category.title(language), field: .category)
                        Divider()
                        detailRow(language.text("מיקום", "Location"), value: location, field: .location)
                        Divider()
                        detailRow(language.text("מועד הצילום", "Photo time"), value: reportTime, field: .time)
                    }.padding(.horizontal, 14).background(Color(.secondarySystemGroupedBackground)).cornerRadius(14)
                    Text(language.text("סוג הדיווח, המיקום והמועד טרם נותחו בגרסה זו. השלימו ובדקו את הפרטים; זיהוי אינו הוכחה לעבירה.", "Category, location and photo time are not analyzed in this version yet. Complete and verify the details; recognition is not proof of an offence.")).font(.caption).foregroundColor(.secondary)
                    Button {} label: { Label(language.text("שלח", "Send"), systemImage: "paperplane.fill").font(.headline).frame(maxWidth: .infinity).frame(height: 52) }.foregroundColor(.white).background(Color.gray).cornerRadius(14).disabled(true)
                    Text(language.text("אין שליחת דיווח בגרסה זו", "No report submission in this version")).font(.footnote.weight(.medium)).foregroundColor(accent)
                    Button(language.text("צילום מחדש", "Retake photo")) { review = false }.frame(minHeight: 44)
                    Text(language.text("התמונה והזיהוי נשארים במכשיר. הפרופיל מוצפן מקומית.", "Photo and recognition stay on-device. Profile is encrypted locally.")).font(.caption).foregroundColor(Color(.secondaryLabel))
                }.padding(16)
            }.background(Color(.systemGroupedBackground))
    }
    private func detailRow(_ title: String, value: String, field: DetailField) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value.isEmpty ? language.text("נדרש להשלים", "Needs confirmation") : value).font(.subheadline.weight(.medium))
            }
            Spacer()
            if field == .category {
                Menu {
                    ForEach(ReportCategory.allCases) { value in Button(value.title(language)) { category = value } }
                } label: { Image(systemName: "chevron.down").frame(width: 44, height: 44) }.accessibilityLabel(language.text("תיקון סוג דיווח", "Correct category"))
            } else {
                Button { detailEditor = field } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel(language.text("עריכת ", "Edit ")+title)
            }
        }.frame(minHeight: 56)
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
        image = photo; plate = ""; recognition = PlateRecognition(candidates: [], confidence: 0); status = ""; busy = true; category = .unknown; draft = CategoryReviewDraft(); location = ""; reportTime = ""
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
            DispatchQueue.main.async { guard revision == token else { return }; recognition = found; plate = found.candidates.count == 1 ? found.candidates[0] : ""; editing = found.needsCorrection; status = found.candidates.isEmpty ? language.text("לא זוהתה לוחית. הקלידו ידנית.", "No plate found. Enter it manually.") : ""; busy = false; review = true }
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
            Button(language.text("שמירה במכשיר", "Save locally")) { do { try store.save(profile); status = language.text("נשמר במכשיר.", "Saved on this device.") } catch { status = language.text("השמירה נכשלה. שום פרט לא נשלח.", "Could not save. No profile was sent.") } }.disabled(!canSave)
            Button(language.text("מחיקת הפרופיל", "Delete local profile"), role: .destructive) { do { try store.delete(); profile = ReporterProfile(); canSave = true; status = language.text("נמחק.", "Deleted.") } catch { status = language.text("מחיקת הפרופיל נכשלה.", "Could not delete the profile.") } }
            Text(status)
        }.navigationTitle(language.text("הגדרות", "Settings")).navigationBarTitleDisplayMode(.inline).onAppear {
            do { profile = try store.load(); canSave = true } catch { canSave = false; status = language.text("לא ניתן לפתוח את הפרופיל. הוא לא הוחלף. פתחו את נעילת המכשיר ונסו שוב, או מחקו אותו.", "Could not unlock the saved profile. It was not replaced. Unlock this phone and retry, or explicitly delete it.") }
        }
    }
}
