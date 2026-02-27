//
//  CalculationHistoryItem.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 26.02.2026.
//

import SwiftUI

struct CalculationHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date

    // Входные параметры
    let area: String
    let rooms: String
    let bathrooms: String
    let garage: String
    let distance: String
    let floor: String
    let buildYear: String
    let balcony: Int
    let renovation: Int

    // Параметры ипотеки
    let loanTerm: Double
    let downPayment: Double
    let interestRate: Double

    // Результаты
    let predictedPrice: Double
    let monthlyPayment: Double
}
