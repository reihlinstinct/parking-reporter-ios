import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    let receive: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(receive) }
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(); config.filter = .images; config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config); picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let receive: (UIImage?) -> Void
        init(_ receive: @escaping (UIImage?) -> Void) { self.receive = receive }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                receive(nil); return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async { self.receive(object as? UIImage) }
            }
        }
    }
}
struct CameraPicker: UIViewControllerRepresentable {
    let receive: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(receive) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let camera = UIImagePickerController(); camera.sourceType = .camera; camera.delegate = context.coordinator
        return camera
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let receive: (UIImage?) -> Void
        init(_ receive: @escaping (UIImage?) -> Void) { self.receive = receive }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { receive(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            receive(info[.originalImage] as? UIImage)
        }
    }
}
