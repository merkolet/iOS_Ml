//
//  ContentView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var inputText = "Я очень доволен этим продуктом! Работает отлично."
    @State private var showingPhotoImport = false
    @State private var showingDetails = false
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Поле ввода с анализом в реальном времени
                    RealTimeAnalysisView(text: $inputText, viewModel: viewModel)
                    
                    // Поле ввода текста
                    TextEditorView(text: $inputText)
                    
                    // Кнопка анализа
                    AnalysisButton(viewModel: viewModel, text: inputText)
                    
                    // Результаты анализа
                    AnalysisResultsView(viewModel: viewModel)
                    
                    // Тестовые примеры
                    TestCasesView(viewModel: viewModel, inputText: $inputText)
                    
                    // Детали анализа
                    AnalysisDetailsView(viewModel: viewModel, isExpanded: $showingDetails)
                    
                }
                .padding()
            }
            .navigationTitle("Анализатор тональности")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: isDarkMode ? "moon.fill" : "moon")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: showingDetails ? "info.circle.fill" : "info.circle")
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onReceive(NotificationCenter.default.publisher(for: .requestPhotoImport)) { _ in
            showingPhotoImport = true
        }
        .sheet(isPresented: $showingPhotoImport) {
            PhotoImportView(importedText: $inputText)
        }
    }
}

struct TextEditorView: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Введите текст для анализа:")
                .font(.headline)
            
            TextEditor(text: $text)
                .frame(height: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Text("Символов: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    NotificationCenter.default.post(name: .requestPhotoImport, object: nil)
                } label: {
                    Label("Импорт из фото", systemImage: "camera.text.magnifyingglass")
                }
                .font(.caption)
                
                Button("Очистить") {
                    text = ""
                }
                .font(.caption)
                .disabled(text.isEmpty)
            }
        }
    }
}

struct AnalysisButton: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let text: String
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.analyzeText(text)
                }
        }) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                Text("Анализировать тональность")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(text.isEmpty)
        .opacity(text.isEmpty ? 0.6 : 1)
    }
}

struct RealTimeAnalysisView: View {
    @Binding var text: String
    @ObservedObject var viewModel: AnalysisViewModel
    @State private var realTimeResult: Sentiment? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Анализ в реальном времени:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let sentiment = realTimeResult, text.count > 10 {
                HStack {
                    Text(sentiment.emoji)
                    Text(sentiment.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(sentiment.color)
                }
                .transition(.opacity)
            }
        }
        .onChange(of: text) { newValue in
            // Запускаем анализ с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                performQuickAnalysis(newValue)
            }
        }
    }
    
    private func performQuickAnalysis(_ text: String) {
        guard text.count > 10 else {
            realTimeResult = nil
            return
        }
        
        let positiveWords = [
            "хорошо", "отлично", "супер",
            "нравится", "доволен"
        ]
        
        let negativeWords = [
            "плохо", "ужасно", "кошмар",
            "ненавижу", "сломался"
        ]
        
        var score = 0
        let words = text.lowercased().split(separator: " ")
        
        for word in words {
            if positiveWords.contains(String(word)) { score += 1 }
            if negativeWords.contains(String(word)) { score -= 1 }
        }
        
        if score > 0 {
            realTimeResult = .positive
        } else if score < 0 {
            realTimeResult = .negative
        } else {
            realTimeResult = .neutral
        }
    }
}

extension Notification.Name {
    static let requestPhotoImport = Notification.Name("requestPhotoImport")
}

#Preview {
    ContentView()
}
