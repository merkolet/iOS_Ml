//
//  MortgageCalculatorViewModel.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 26.02.2026.
//

import SwiftUI
import Foundation
import CoreML
import Combine

final class MortgageCalculatorViewModel: ObservableObject {
    
    // MARK: - Входные параметры недвижимости (из View)
    @Published var area: String = "75"
    @Published var rooms: String = "3"
    @Published var bathrooms: String = "2"
    @Published var garage: String = "1"
    @Published var distance: String = "2.5"
    @Published var floor: String = "5"
    @Published var buildYear: String = "2010"
    
    // Новые параметры
    @Published var renovation: Int = 0
    @Published var balcony: Int = 0
    
    // MARK: - Настройки ипотеки
    @Published var loanTerm: Double = 20
    @Published var downPayment: Double = 20
    @Published var interestRate: Double = 7.5
    
    // MARK: - Результаты
    @Published var predictedPrice: Double?
    @Published var monthlyPayment: Double?
    @Published var isCalculating: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - История
    @Published var history: [CalculationHistoryItem] = []
    
    private let historyKey = "calculationHistory_v1"
    private let maxHistoryCount = 30
    
    // MARK: - Дебаунсер
    private var calculationWorkItem: DispatchWorkItem?
    
    // MARK: - График платежа
    var paymentChartData: [PaymentPoint] {
        guard let price = predictedPrice else { return [] }
        
        return Array(stride(from: 5, through: 30, by: 1)).map { term in
            let payment = calculateMonthlyPayment(
                price: price,
                downPaymentPercent: downPayment,
                loanTerm: Double(term),
                interestRate: interestRate
            )
            return PaymentPoint(term: term, payment: payment)
        }
    }
    
    // MARK: - Инициализация
    init() {
        loadHistory()
        debouncedCalculate()
    }
    
    // MARK: - Публичные методы для View
    
    func debouncedCalculate() {
        calculationWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.calculateFull()
        }
        
        calculationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    func calculateFull() {
        let validation = validateInput()
        guard validation.isValid else {
            DispatchQueue.main.async {
                self.errorMessage = validation.errorMessage
                self.predictedPrice = nil
            }
            return
        }
        
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.isCalculating = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let price = self.predictHousePrice()
            let payment = self.calculateMonthlyPayment(
                price: price,
                downPaymentPercent: self.downPayment,
                loanTerm: self.loanTerm,
                interestRate: self.interestRate
            )
            
            DispatchQueue.main.async {
                self.predictedPrice = price
                self.monthlyPayment = payment
                self.isCalculating = false
                self.appendHistory(predictedPrice: price, monthlyPayment: payment)
            }
        }
    }
    
    func recalculateMortgageOnly() {
        guard let price = predictedPrice else {
            debouncedCalculate()
            return
        }
        
        monthlyPayment = calculateMonthlyPayment(
            price: price,
            downPaymentPercent: downPayment,
            loanTerm: loanTerm,
            interestRate: interestRate
        )
    }
    
    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    // MARK: - ML Предсказание цены
    
    private func predictHousePrice() -> Double {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all // CPU + GPU + Neural Engine
            
            let model = try HousePricePredictor(configuration: config)
            
            guard
                let areaValue = Double(area),
                let roomsValue = Double(rooms),
                let bathroomsValue = Double(bathrooms),
                let garageValue = Double(garage),
                let distanceValue = Double(distance),
                let floorValue = Double(floor),
                let buildYearValue = Double(buildYear)
            else {
                return calculateFallbackPrice()
            }
            
            let input = HousePricePredictorInput(
                area: Int64(areaValue),
                total_rooms: Int64(roomsValue),
                bathrooms: Int64(bathroomsValue),
                garage_spaces: Int64(garageValue),
                distance_to_center: distanceValue,
                floor: Int64(floorValue),
                build_year: Int64(buildYearValue),
                balcony: Int64(balcony),
                renovation: Int64(renovation)
            )
            
            let prediction = try model.prediction(input: input)
            return prediction.price
            
        } catch {
            print("Ошибка ML: \(error)")
            return calculateFallbackPrice()
        }
    }
    
    // MARK: - Резервный расчет (если ML недоступен)
    
    private func calculateFallbackPrice() -> Double {
        guard
            let areaValue = Double(area),
            let roomsValue = Double(rooms),
            let distValue = Double(distance),
            let yearValue = Double(buildYear)
        else {
            return 0
        }
        
        let basePricePerSqm = 60_000.0
        let roomBonus = roomsValue * 200_000
        let distanceDiscount = distValue * 100_000
        let yearBonus = (yearValue - 2000) * 10_000
        
        let total =
            (areaValue * basePricePerSqm) +
            roomBonus -
            distanceDiscount +
            yearBonus
        
        return max(total, 1_000_000)
    }
    
    // MARK: - Расчет аннуитетного платежа
    
    func calculateMonthlyPayment(
        price: Double,
        downPaymentPercent: Double,
        loanTerm: Double,
        interestRate: Double
    ) -> Double {
        let loanAmount = price * (100 - downPaymentPercent) / 100
        let monthlyRate = (interestRate / 100) / 12
        let months = loanTerm * 12
        
        guard monthlyRate > 0 else {
            return loanAmount / months
        }
        
        let compound = pow(1 + monthlyRate, months)
        let coefficient = monthlyRate * compound
        let denominator = compound - 1
        
        guard denominator > 0 else {
            return loanAmount / months
        }
        
        return loanAmount * (coefficient / denominator)
    }
    
    // MARK: - Валидация ввода
    
    private func validateInput() -> (isValid: Bool, errorMessage: String?) {
        let fields: [(String, String)] = [
            (area, "Площадь"),
            (rooms, "Количество комнат"),
            (bathrooms, "Количество санузлов"),
            (garage, "Парковочные места"),
            (distance, "Расстояние до центра"),
            (floor, "Этаж"),
            (buildYear, "Год постройки")
        ]
        
        for (value, fieldName) in fields {
            guard let number = Double(value), number >= 0 else {
                return (false, "Поле '\(fieldName)' должно быть положительным числом")
            }
        }
        
        if let year = Double(buildYear) {
            let currentYear = Calendar.current.component(.year, from: Date())
            if year < 1900 || Int(year) > currentYear + 5 {
                return (false, "Год постройки должен быть между 1900 и \(currentYear + 5)")
            }
        }
        
        if let areaVal = Double(area), areaVal < 10 || areaVal > 1000 {
            return (false, "Площадь должна быть реалистичной (10-1000 м²)")
        }
        
        return (true, nil)
    }
    
    // MARK: - История (UserDefaults)
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        if let decoded = try? JSONDecoder().decode([CalculationHistoryItem].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
    
    private func appendHistory(predictedPrice: Double, monthlyPayment: Double) {
        if let last = history.first,
           last.area == area,
           last.rooms == rooms,
           last.bathrooms == bathrooms,
           last.garage == garage,
           last.distance == distance,
           last.floor == floor,
           last.buildYear == buildYear,
           last.balcony == balcony,
           last.renovation == renovation,
           abs(last.loanTerm - loanTerm) < 0.0001,
           abs(last.downPayment - downPayment) < 0.0001,
           abs(last.interestRate - interestRate) < 0.0001,
           abs(last.predictedPrice - predictedPrice) < 0.5,
           abs(last.monthlyPayment - monthlyPayment) < 0.5 {
            return
        }
        
        let item = CalculationHistoryItem(
            id: UUID(),
            date: Date(),
            area: area,
            rooms: rooms,
            bathrooms: bathrooms,
            garage: garage,
            distance: distance,
            floor: floor,
            buildYear: buildYear,
            balcony: balcony,
            renovation: renovation,
            loanTerm: loanTerm,
            downPayment: downPayment,
            interestRate: interestRate,
            predictedPrice: predictedPrice,
            monthlyPayment: monthlyPayment
        )
        
        history.insert(item, at: 0)
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        saveHistory()
    }
}
