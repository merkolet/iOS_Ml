//
//  AnalysisDetailsView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct AnalysisDetailsView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        if isExpanded, !viewModel.analysisDetails.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Полные детали анализа")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { isExpanded = false }) {
                        Image(systemName: "chevron.up")
                    }
                }
                
                ForEach(viewModel.analysisDetails, id: \.title) { detail in
                    AnalysisDetailRow(detail: detail)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
    }
}
