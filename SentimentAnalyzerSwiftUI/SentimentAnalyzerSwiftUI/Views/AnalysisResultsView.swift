//
//  AnalysisResultsView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isAnalyzing {
                ProgressView("Анализ текста...")
                    .padding()
                    
            } else if let result = viewModel.result {
                SentimentCard(result: result)
                ConfidenceIndicator(confidence: result.confidence)
                SentimentVisualization(result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                
                Text("Детали анализа:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(result.details, id: \.title) { detail in
                    AnalysisDetailRow(detail: detail)
                }
                
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
