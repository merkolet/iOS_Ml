//
//  Classifier.swift
//  Ml_Hw1
//
//  Created by Sergey on 22.01.2026.
//

import Vision
import CoreML
import UIKit

final class Classifier {

    private let vnModel: VNCoreMLModel

    init() {
        let mlModel = try! MyModel(configuration: MLModelConfiguration()).model
        self.vnModel = try! VNCoreMLModel(for: mlModel)
    }

    func classify(_ image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("No CGImage")
            return
        }

        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error = error {
                completion("Error: \(error)")
                return
            }

            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else {
                completion("No results")
                return
            }

            completion("\(top.identifier) (\(top.confidence))")
        }

        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion("Handler error: \(error)")
            }
        }
    }
}
