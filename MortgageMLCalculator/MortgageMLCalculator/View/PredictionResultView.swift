//
//  PredictionResultView.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 14.02.2026.
//

import SwiftUI

/// Компонент отображения прогноза цены и ипотечных условий
struct PredictionResultView: View {
    
    let price: Double
    let monthlyPayment: Double?
    let downPayment: Double
    let loanTerm: Double
    let interestRate: Double
    
    // MARK: - Форматирование валюты
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")

        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Прогнозируемая стоимость
            VStack(alignment: .leading, spacing: 4) {
                Text("Прогнозируемая стоимость")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(priceFormatter.string(from: NSNumber(value: price)) ?? "")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            // MARK: - Ипотечный расчет
            if let payment = monthlyPayment {
                VStack(alignment: .leading, spacing: 10) {
                    
                    Text("Ипотечный расчет")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    let creditAmount = price * (100 - downPayment) / 100
                    
                    // Первоначальный взнос
                    HStack {
                        Text("Первоначальный взнос:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(downPayment))%")
                            .fontWeight(.medium)
                    }
                    
                    // Сумма кредита
                    HStack {
                        Text("Сумма кредита:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(priceFormatter.string(from: NSNumber(value: creditAmount)) ?? "")
                            .fontWeight(.medium)
                    }
                    
                    // Ежемесячный платеж
                    HStack {
                        Text("Ежемесячный платеж:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(priceFormatter.string(from: NSNumber(value: payment)) ?? "")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.green)
                    }
                    
                    // Переплата
                    HStack {
                        Text("Переплата за \(Int(loanTerm)) лет:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let totalPayment = payment * loanTerm * 12
                        let overpayment = totalPayment - creditAmount
                        
                        Text(priceFormatter.string(from: NSNumber(value: overpayment)) ?? "")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    // Процент переплаты
                    if creditAmount > 0 {
                        let overpaymentPercent =
                            (payment * loanTerm * 12 - creditAmount) /
                            creditAmount * 100
                        
                        HStack {
                            Text("Переплата:")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%%", overpaymentPercent))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct PredictionResultView_Previews: PreviewProvider {
    
    static var previews: some View {
        List {
            PredictionResultView(
                price: 5_500_000,
                monthlyPayment: 35_420,
                downPayment: 20,
                loanTerm: 20,
                interestRate: 7.5
            )
        }
    }
}
