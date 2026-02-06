//
//  SentimentVisualization.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct SentimentVisualization: View {
    let result: TextAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Графики статистики")
                .font(.headline)
            
            StatBar(
                title: "Кол-во слов",
                value: Double(result.wordCount),
                maxValue: 200,
                color: .blue
            )
            
            StatBar(
                title: "Кол-во предложений",
                value: Double(max(result.wordCount == 0 ? 0 : result.wordCount / max(1, result.wordCount / result.wordCount),
                                   result.wordCount / max(1, result.wordCount / max(1, result.wordCount)))),
                maxValue: 20,
                color: .orange
            )
            
            StatBar(
                title: "Уверенность",
                value: result.confidence,
                maxValue: 1.0,
                color: .green,
                formatter: { value in "\(Int(value * 100))%" }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct StatBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    var formatter: ((Double) -> String)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.8))
                        .frame(width: CGFloat(min(value / maxValue, 1.0)) * geo.size.width)
                        .animation(.easeOut(duration: 0.5), value: value)
                }
            }
            .frame(height: 10)
        }
    }
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter(value)
        } else {
            return String(Int(value))
        }
    }
}
