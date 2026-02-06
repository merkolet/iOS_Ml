//
//  HistoryView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI

struct HistoryView: View {
    @AppStorage("analysisHistory") private var historyData: Data = Data()
    @State private var history: [TextAnalysisResult] = []
    
    var body: some View {
        List {
            ForEach(history, id: \.timestamp) { result in
                HistoryRow(result: result)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("История анализов")
        .onAppear(perform: loadHistory)
    }
    
    private func loadHistory() {
        if let decoded = try? JSONDecoder().decode([TextAnalysisResult].self, from: historyData) {
            history = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            historyData = encoded
        }
    }
}

struct HistoryRow: View {
    let result: TextAnalysisResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.text.prefix(50) + (result.text.count > 50 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)
                
                HStack {
                    Text(result.sentiment.rawValue)
                        .font(.caption)
                        .foregroundColor(result.sentiment.color)
                    
                    Text(result.sentiment.emoji)
                    
                    Spacer()
                    
                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
