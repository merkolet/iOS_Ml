//
//  ClassifierViewModel.swift
//  Ml_Hw1
//
//  Created by Sergey on 06.02.2026.
//

import Foundation
import UIKit
import Combine

final class ClassifierViewModel: ObservableObject {

    @Published var result: String = ""

    private let classifier = Classifier()

    func classifyTestImage() {
        guard let image = UIImage(named: "test") else {
            result = "No test image"
            return
        }

        classify(image)
    }

    func classify(_ image: UIImage) {
        classifier.classify(image) { [weak self] out in
            DispatchQueue.main.async {
                self?.result = out
            }
        }
    }
}
