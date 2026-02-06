//
//  AnalysisDetailRow.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct AnalysisDetailRow: View {
    let detail: TextAnalysisResult.AnalysisDetail
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(detail.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(detail.value)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch detail.type {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .success: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch detail.type {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}
