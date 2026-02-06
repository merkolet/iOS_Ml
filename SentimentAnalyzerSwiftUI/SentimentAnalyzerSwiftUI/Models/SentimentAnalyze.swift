//
//  SentimentAnalyze.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Sergey on 23.01.2026.
//

import NaturalLanguage
import CoreML

class SentimentAnalyzer {
    
    /// 2. Получение кастомной модели токсичности.
    private lazy var toxicityModel: ToxicityClassifier? = {
        do {
            let config = MLModelConfiguration()
            return try ToxicityClassifier(configuration: config)
        } catch {
            print("Не удалось загрузить модель токсичности: \(error)")
            return nil
        }
    }()
    
    // MARK: - Базовый анализ NLP
    
    func analyze(_ text: String) async throws -> TextAnalysisResult {
        var details: [TextAnalysisResult.AnalysisDetail] = []
        
        // 1. Определение языка
        let language = try await detectLanguage(text)
        details.append(.init(title: "Язык", value: language, type: .info))
        
        // 2. Токенизация и статистика
        let (wordCount, sentences) = try await tokenize(text)
        details.append(.init(
            title: "Статистика",
            value: "\(wordCount) слов, \(sentences) предложений",
            type: .info
        ))
        
        /// 2.1. Анализ удобочитаемости текста
        let readability = try await analyzeReadability(
            text: text,
            wordCount: wordCount,
            sentenceCount: sentences
        )
        details.append(.init(
            title: "Сложность текста",
            value: readability,
            type: .info
        ))
        
        // 3. Анализ тональности
        let (sentiment, confidence) = try await analyzeSentiment(text)
        
        /// 3.1 Анализ эмоции.
        let (emotion, emotionConfidence) = try await detectEmotion(text)
        details.append(.init(
            title: "Эмоция",
            value: "\(emotion) (\(Int(emotionConfidence * 100))%)",
            type: .info
        ))
        
        // 4. Определение частей речи
        let posDetails = try await analyzePartsOfSpeech(text)
        details.append(contentsOf: posDetails)
        
        // 5. Поиск именованных сущностей
        let entities = try await findNamedEntities(text)
        if !entities.isEmpty {
            details.append(.init(
                title: "Именованные сущности",
                value: entities.joined(separator: ", "),
                type: .info
            ))
        }
        
        // 6. Проверка на токсичность
        let isToxic = try await checkToxicity(text)
        print(isToxic)
        if isToxic {
            details.append(.init(
                title: "⚠️ Предупреждение",
                value: "Обнаружен потенциально токсичный контент",
                type: .warning
            ))
        }
        
        return TextAnalysisResult(
            text: text,
            sentiment: sentiment,
            confidence: confidence,
            language: language,
            wordCount: wordCount,
            entities: entities,
            details: details,
            timestamp: Date()
        )
    }
    
    // MARK: - Детектирование языка
    
    private func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return "Не определен"
        }
        
        return language.rawValue
    }
    
    // MARK: - Токенизация
    
    private func tokenize(_ text: String) async throws -> (wordCount: Int, sentenceCount: Int) {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        
        var wordCount = 0
        var sentenceCount = 0
        
        // Подсчет слов
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .tokenType,
            options: [.omitPunctuation, .omitWhitespace]
        ) { _, _ in
            wordCount += 1
            return true
        }
        
        // Подсчет предложений
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .sentence,
            scheme: .tokenType
        ) { _, _ in
            sentenceCount += 1
            return true
        }
        
        return (wordCount, sentenceCount)
    }
    
    // MARK: - Анализ тональности
    
    private func analyzeSentiment(_ text: String) async throws -> (Sentiment, Double) {
        // Сначала пробуем встроенный анализатор
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        if let sentimentTag = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        ).0,
           let score = Double(sentimentTag.rawValue) {
            
            let sentiment: Sentiment
            switch score {
            case 0.3...:
                sentiment = .positive
            case -0.3..<0.3:
                sentiment = .neutral
            default:
                sentiment = .negative
            }
            
            return (sentiment, abs(score))
        }
        
        // Если встроенный не сработал, используем кастомную модель
        return try await analyzeWithCustomModel(text)
    }
    
    // MARK: - Определение эмоций (радость, грусть, злость)

    private func detectEmotion(_ text: String) async throws -> (emotion: String, confidence: Double) {
        let lowercasedText = text.lowercased()

        let joyWords = [
            "рад", "рада", "рады", "счастлив", "счастлива", "доволен", "довольна",
            "радость", "счастье", "кайф", "классно", "круто", "здорово", "супер",
            "обожаю", "люблю", "очень нравится", "очень понравилось", "в восторге"
        ]

        let sadnessWords = [
            "грустно", "печально", "грусть", "депрессия", "одиночество",
            "расстроен", "расстроена", "разочарован", "разочарована",
            "плохо на душе", "подавлен", "тоскливо", "мне плохо", "хочется плакать"
        ]

        let angerWords = [
            "злой", "злая", "злюсь", "ярость", "злость", "бесит", "раздражает",
            "ненавижу", "выбесили", "вы бесите", "разозлили", "яростно", "киплю",
            "очень злюсь", "я в ярости", "взбешён", "взбешена", "ужас"
        ]

        var joyScore = 0
        var sadnessScore = 0
        var angerScore = 0

        for word in joyWords where lowercasedText.contains(word) {
            joyScore += 1
        }
        for word in sadnessWords where lowercasedText.contains(word) {
            sadnessScore += 1
        }
        for word in angerWords where lowercasedText.contains(word) {
            angerScore += 1
        }

        let scores = [
            ("Радость", joyScore),
            ("Грусть", sadnessScore),
            ("Злость", angerScore)
        ]

        // Нет явных эмоциональных слов - считаем эмоцию неопределённой
        guard let (bestEmotion, bestScore) = scores.max(by: { $0.1 < $1.1 }),
              bestScore > 0 else {
            return ("Неопределено", 0.4)
        }

        let totalScore = joyScore + sadnessScore + angerScore
        let confidence: Double
        if totalScore == 0 {
            confidence = 0.4
        } else {
            let ratio = Double(bestScore) / Double(totalScore)
            confidence = min(0.95, 0.5 + ratio * 0.4 + Double(totalScore) * 0.05)
        }

        return (bestEmotion, confidence)
    }
    
    // MARK: - Кастомная модель
    
    private func analyzeWithCustomModel(_ text: String) async throws -> (Sentiment, Double) {
        // Если кастомная модель не найдена, используем простой эвристический анализ
        // Основанный на ключевых словах и структуре текста
        
        /// 1. Увеличено кол-во позитивных и негативных слов.
        let positiveWords = [
                "хорошо", "отлично", "прекрасно", "замечательно", "супер", "классно", "круто",
                "приятно", "здорово", "нравится", "люблю", "обожаю",
                "рад", "рада", "рады", "счастлив", "счастлива", "доволен", "довольна",
                "очень рад", "очень рада", "очень доволен", "очень довольна",
                "безумно рад", "безумно рада", "очень понравилось", "очень нравится",
                "отличный сервис", "прекрасный сервис", "хорошее приложение",
                "удобно", "комфортно", "понравилось", "понравился", "понравилась", "понравились",
                "рекомендую", "советую", "топ", "огонь"
            ]
        let negativeWords = [
                "плохо", "ужасно", "отвратительно", "мерзко", "ужасный", "отвратительный",
                "ненавижу", "ненависть", "злой", "злая", "злость", "грустно", "печально",
                "разочарован", "разочарована", "разочарование",
                "проблема", "проблемы", "баг", "баги", "лаги", "лагает", "тормозит", "зависает",
                "не работает", "не запускается", "не открывается", "не загружается",
                "сломалось", "сломался", "сломана",
                "ужасный сервис", "кошмарный сервис", "плохое приложение", "отстой", "фигня",
                "раздражает", "напрягает", "ненормально",
                "ненавижу это", "ненавижу вас", "ненавижу приложение", "бесит", "бесите",
                "кошмар", "катастрофа"
            ]
        
        let lowercasedText = text.lowercased()
        var positiveScore = 0
        var negativeScore = 0
        
        for word in positiveWords {
            if lowercasedText.contains(word) {
                positiveScore += 1
            }
        }
        
        for word in negativeWords {
            if lowercasedText.contains(word) {
                negativeScore += 1
            }
        }
        
        // Определяем тональность на основе баланса
        let totalScore = positiveScore + negativeScore
        guard totalScore > 0 else {
            return (.neutral, 0.5)
        }
        
        let positiveRatio = Double(positiveScore) / Double(totalScore)
        let confidence = min(0.9, Double(totalScore) * 0.1 + 0.5)
        
        let sentiment: Sentiment
        if positiveRatio > 0.6 {
            sentiment = .positive
        } else if positiveRatio < 0.4 {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }
        
        return (sentiment, confidence)
    }
    
    // MARK: - Анализ сложности текста (индекс удобочитаемости)

    private func analyzeReadability(text: String, wordCount: Int, sentenceCount: Int) async throws -> String {
        guard wordCount > 0, sentenceCount > 0 else {
            return "Недостаточно текста для оценки"
        }

        // Средняя длина предложения
        let avgSentenceLength = Double(wordCount) / Double(sentenceCount)

        // Средняя длина слова
        let words = text
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }

        let totalChars = words.reduce(0) { $0 + $1.count }
        let avgWordLength = words.isEmpty ? 0.0 : Double(totalChars) / Double(words.count)

        // Простая эвристика:
        // - короткие предложения и слова → текст простой
        // - средние → средний
        // - длинные → сложный
        let complexityLevel: String
        let explanation: String

        switch (avgSentenceLength, avgWordLength) {
        case (..<12, ..<6):
            complexityLevel = "Простой"
            explanation = "короткие предложения и относительно короткие слова"
        case (12..<20, 6..<8):
            complexityLevel = "Средний"
            explanation = "средняя длина предложений и слов"
        default:
            complexityLevel = "Сложный"
            explanation = "длинные предложения и/или длинные слова"
        }

        let roundedSentenceLength = String(format: "%.1f", avgSentenceLength)
        let roundedWordLength = String(format: "%.1f", avgWordLength)

        return "\(complexityLevel) — ср. длина предложения: \(roundedSentenceLength) слов, ср. длина слова: \(roundedWordLength) символов (\(explanation)"
    }
    
    // MARK: - Дополнительные функции NLP
    
    private func analyzePartsOfSpeech(_ text: String) async throws -> [TextAnalysisResult.AnalysisDetail] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var posCount: [String: Int] = [:]
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitPunctuation, .omitWhitespace]
        ) { tag, _ in
            if let tag = tag {
                posCount[tag.rawValue, default: 0] += 1
            }
            return true
        }
        
        return posCount.map {
            TextAnalysisResult.AnalysisDetail(
                title: "Часть речи: \($0.key)",
                value: "\($0.value)",
                type: .info
            )
        }
    }
    
    private func findNamedEntities(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.joinNames]
        ) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entity = String(text[range])
                entities.append("\(entity) (\(tag.rawValue))")
            }
            return true
        }
        
        return entities
    }
    
    private func checkToxicity(_ text: String) async throws -> Bool {
        let lowercasedText = text.lowercased()

        // Сначала используем кастомную модель
        if let model = toxicityModel {
            if let prediction = try? model.prediction(text: text) {
                if prediction.label == "toxic" {
                    return true
                }
            }
        }

        let toxicPatterns = [
            "идиот", "идиотка", "дурак", "дура", "тупой", "тупица", "дебил", "кретин",
            "мразь", "скотина", "урод", "уродище",
            "ненавижу тебя", "ненавижу вас", "убей себя", "сдохни", "сдохните",
            "я тебя ненавижу", "я вас ненавижу",
            "ублюд", "падла"
        ]

        return toxicPatterns.contains { lowercasedText.contains($0) }
    }
    
    // MARK: - Ошибки
    
    enum AnalysisError: Error {
        case modelNotFound
        case invalidText
        case analysisFailed
    }
}
