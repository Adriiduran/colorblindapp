//
//  CameraPicker.swift
//  colorblindapp
//

import SwiftUI
import UIKit

/// Captura una foto con la cámara del sistema para dar de alta una prenda.
/// `PhotosPicker` no ofrece una fuente de cámara, así que se envuelve
/// `UIImagePickerController` (suficiente para una captura puntual; el
/// escáner en vivo usa `AVFoundation` aparte para su caso de uso distinto).
struct CameraPicker: UIViewControllerRepresentable {
    /// `nil` si el usuario cancela.
    let onCapture: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data?) -> Void

        init(onCapture: @escaping (Data?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image?.jpegData(compressionQuality: 0.9))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
        }
    }
}
