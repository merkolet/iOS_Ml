//
//  ContentView.swift
//  Ml_Hw1
//
//  Created by Sergey on 22.01.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ClassifierViewModel()

    var body: some View {
        VStack(spacing: 20) {

            Text("Домашнее задание №1")
                .font(.title)
                .fontWeight(.semibold)

            
            Text("Пример изображения")

            Image("test")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .cornerRadius(12)
                .shadow(radius: 4)

            Text("Результат:")
                .font(.subheadline)

            Text(viewModel.result.isEmpty ? "—" : viewModel.result)
                .font(.headline)

            Button("Классифицировать") {
                viewModel.classifyTestImage()
            }
        }
        .padding()
    }
}

