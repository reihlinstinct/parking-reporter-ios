import SwiftUI
import Vision
import AVFoundation

@main struct ReporterApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}
struct ContentView: View {
    @State private var image: UIImage?
    @State private var candidates: [String] = []
    @State private var plate = ""
    @State private var status = ""
    @State private var picker: PickerKind?
    @State private var busy = false
    @State private var revision = UUID()
    enum PickerKind: String, Identifiable { case camera, library; var id: String { rawValue } }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Development preview")) {
                    Text("Photos and text recognition stay on this device. Nothing is submitted. No analytics SDK is included.")
                    Text("The profile is encrypted locally. Camera/photos are not saved by this preview after closing it.")
                }
                Section(header: Text("Photo")) {
                    Button("Take photo") { requestCamera() }.disabled(busy)
                    Button("Choose photo") { picker = .library }.disabled(busy)
                    if let image = image { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240) }
                    if busy { ProgressView("Reading text locally...") }
                    Text(status)
                }
                Section(header: Text("Plate candidates - verify manually")) {
                    ForEach(candidates, id: \.self) { candidate in Button(candidate) { plate = candidate } }
                    TextField("Correct plate", text: $plate).keyboardType(.numberPad)
                    Text("Recognition is not proof of a plate or an offence. No send button is enabled.")
                }
                Section { NavigationLink("Reporter profile") { ProfileView() } }
            }.navigationTitle("Parking Reporter")
            .sheet(item: $picker) { selected in
                if selected == .camera { CameraPicker(receive: accept) } else { PhotoPicker(receive: accept) }
            }
        }.navigationViewStyle(.stack)
    }
    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { status = "Camera unavailable on this device."; return }
        AVCaptureDevice.requestAccess(for: .video) { granted in DispatchQueue.main.async {
            if granted { picker = .camera } else { status = "Camera permission denied. You can still choose a photo." }
        } }
    }
    private func accept(_ photo: UIImage?) {
        picker = nil
        guard let photo = photo else { return }
        image = photo; plate = ""; candidates = []; status = ""; busy = true
        let token = UUID(); revision = token
        // Re-render orientation and bound work on older phones. Original review image stays untouched in RAM.
        DispatchQueue.global(qos: .userInitiated).async {
            let maxSide: CGFloat = 2000
            let ratio = min(1, maxSide / max(photo.size.width, photo.size.height))
            let size = CGSize(width: max(1, photo.size.width * ratio), height: max(1, photo.size.height * ratio))
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in photo.draw(in: CGRect(origin: .zero, size: size)) }
            var found: [String] = []; var message = "No candidates. Enter the plate manually."
            do {
                guard let cg = normalized.cgImage else { throw ProfileError.corrupt }
                let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false; request.recognitionLanguages = ["en-US"]
                try VNImageRequestHandler(cgImage: cg).perform([request])
                found = PlateCandidates.parse((request.results ?? []).compactMap { $0.topCandidates(1).first?.string })
                if !found.isEmpty { message = "Choose a candidate and verify it against the photo." }
            } catch { message = "Text recognition failed. Enter the plate manually." }
            DispatchQueue.main.async { guard revision == token else { return }; candidates = found; status = message; busy = false }
        }
    }
}
struct ProfileView: View {
    @State private var profile = ReporterProfile()
    @State private var status = ""
    @State private var canSave = false
    private let store = ProfileStore()
    var body: some View {
        Form {
            Text("Stored only on this device, encrypted with a device-only Keychain key. Not synced. Deleting the app may leave the Keychain key behind; use Delete to clear this profile.")
            TextField("First name", text: $profile.first)
            TextField("Last name", text: $profile.last)
            TextField("Phone", text: $profile.phone).keyboardType(.phonePad)
            TextField("ID", text: $profile.identifier).keyboardType(.numberPad)
            TextField("Email", text: $profile.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
            Button("Save locally") { do { try store.save(profile); status = "Saved on this device." } catch { status = "Could not save. No profile was sent." } }.disabled(!canSave)
            Button("Delete local profile", role: .destructive) { do { try store.delete(); profile = ReporterProfile(); canSave = true; status = "Deleted." } catch { status = "Could not delete the profile." } }
            Text(status)
        }.navigationTitle("Reporter profile").onAppear {
            do { profile = try store.load(); canSave = true } catch { canSave = false; status = "Could not unlock the saved profile. It was not replaced. Unlock this phone and retry, or explicitly delete it." }
        }
    }
}
