//
//  TestCasesView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct TestCasesView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @Binding var inputText: String
    
    let testCases = [
        ("😊 Позитивный",
         "Я очень доволен покупкой! Отличный сервис и быстрая доставка. Рекомендую всем!"),
        ("😠 Негативный",
         "Ужасный продукт, сломался через день. Деньги на ветер, больше никогда не куплю."),
        ("😐 Нейтральный",
         "Приобрел товар для тестирования. Качество стандартное, доставка заняла 3 дня."),
        ("⚠️ Токсичный",
         "Ты полный идиот, если думаешь, что это работает!")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тестовые примеры:")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(testCases, id: \.0) { title, text in
                        Button(action: {
                            inputText = text
                            viewModel.analyzeText(text)
                        }) {
                            VStack(spacing: 4) {
                                Text(title.components(separatedBy: " ").first ?? "")
                                    .font(.title2)
                                
                                Text(title.components(separatedBy: " ").last ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}
