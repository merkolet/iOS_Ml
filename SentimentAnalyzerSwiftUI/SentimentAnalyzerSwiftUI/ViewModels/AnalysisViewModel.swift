//
//  AnalysisViewModel.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import Foundation
import NaturalLanguage
import SwiftUI
internal import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var result: TextAnalysisResult?
    @Published var isAnalyzing = false
    @Published var analysisDetails: [TextAnalysisResult.AnalysisDetail] = []
    @Published var errorMessage: String?
    
    private let analyzer = SentimentAnalyzer()
    
    func analyzeText(_ text: String) {
        guard !text.isEmpty else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await analyzer.analyze(text)
                self.result = result
                self.analysisDetails = result.details
            } catch {
                self.errorMessage = "Ошибка анализа: \(error.localizedDescription)"
            }
            self.isAnalyzing = false
        }
    }
    
    func clearResults() {
        result = nil
        analysisDetails = []
        errorMessage = nil
    }
}
