//
//  PhotoImportView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 06.02.2026.
//

import SwiftUI
import Vision
import VisionKit

struct PhotoImportView: UIViewControllerRepresentable {

    @Binding var importedText: String

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        let parent: PhotoImportView

        init(_ parent: PhotoImportView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var extractedText = ""

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)

                let textRecognitionRequest = VNRecognizeTextRequest { request, error in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        return
                    }

                    for observation in observations {
                        if let candidate = observation.topCandidates(1).first {
                            extractedText += candidate.string + "\n"
                        }
                    }
                }

                textRecognitionRequest.recognitionLevel = .accurate

                if let cgImage = image.cgImage {
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? requestHandler.perform([textRecognitionRequest])
                }
            }

            parent.importedText = extractedText
            controller.dismiss(animated: true)
        }
    }
}
