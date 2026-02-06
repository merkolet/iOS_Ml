//
//  SentimentCard.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct SentimentCard: View {
    let result: TextAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Результат анализа")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(result.sentiment.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(result.sentiment.color)
                        
                        Text(result.sentiment.emoji)
                            .font(.title2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Уверенность")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(result.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Text("Язык: \(result.language)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(result.sentiment.color.opacity(0.1))
        )
    }
}
