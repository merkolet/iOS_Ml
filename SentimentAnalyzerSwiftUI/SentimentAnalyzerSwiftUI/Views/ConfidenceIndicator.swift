//
//  ConfidenceIndicator.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Уверенность модели:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая линия
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Индикатор уверенности
                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
                        .cornerRadius(4)
                    
                    // Текущая позиция
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * CGFloat(confidence) - 8)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("0%")
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .fontWeight(.semibold)
                Spacer()
                Text("100%")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .orange
        }
    }
}
