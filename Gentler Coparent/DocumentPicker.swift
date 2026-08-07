import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

enum PickerType {
    case photos
    case documents
}

#if canImport(UIKit)
struct DocumentPicker: UIViewControllerRepresentable {
    var pickerType: PickerType
    var callback: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch pickerType {
        case .photos:
            #if canImport(PhotosUI)
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = context.coordinator
            return picker
            #else
            return UIViewController() // Fallback for non-PhotosUI platforms
            #endif
        case .documents:
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
                .image, .pdf, .text, .plainText
            ])
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            print("Document picked from Files: \(url.path)")
            parent.callback(url)
        }

        #if canImport(PhotosUI)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else {
                print("No item provider available from photo picker")
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Failed to load image from photo picker: \(error.localizedDescription)")
                        return
                    }
                    guard let uiImage = image as? UIImage else {
                        print("Loaded object is not a UIImage")
                        return
                    }
                    
                    if let data = uiImage.jpegData(compressionQuality: 1.0) {
                        Task { @MainActor in
                            if let url = self.saveImageToTemporaryFile(data: data) {
                                print("Photo picked from library, saved to: \(url.path)")
                                self.parent.callback(url)
                            }
                        }
                    } else {
                        print("Failed to save image to temporary file")
                    }
                }
            } else {
                print("Item provider cannot load UIImage")
            }
        }
        #endif

        private func saveImageToTemporaryFile(data: Data) -> URL? {
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                print("Failed to save image to temporary file: \(error)")
                return nil
            }
        }
    }
}
#else
struct DocumentPicker: View {
    var pickerType: PickerType
    var callback: (URL) -> Void

    var body: some View {
        Text("Document picking is not supported on this platform.")
            .foregroundColor(.gray)
    }
}
#endif
