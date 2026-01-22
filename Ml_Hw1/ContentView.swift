//
//  ContentView.swift
//  Ml_Hw1
//
//  Created by Sergey on 22.01.2026.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var result = ""
    private let classifier = Classifier()

    var body: some View {
        VStack(spacing: 20) {

            Image("test")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(radius: 4)

            Text("Результат:")
                .font(.subheadline)

            Text(result.isEmpty ? "—" : result)
                .font(.headline)

            Button("Классифицировать") {
                guard let image = UIImage(named: "test") else {
                    result = "No test image"
                    return
                }

                classifier.classify(image) { out in
                    DispatchQueue.main.async {
                        result = out
                    }
                }
            }
        }
        .padding()
    }
}

