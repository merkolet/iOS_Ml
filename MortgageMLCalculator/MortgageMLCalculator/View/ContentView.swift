//
//  ContentView.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 13.02.2026.
//

import SwiftUI
import Charts

struct ContentView: View {
    
    @StateObject private var viewModel = MortgageCalculatorViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                
                // MARK: - Секция 1: Параметры недвижимости
                Section(header: Text("Характеристики недвижимости")) {
                    ParameterRow(title: "Площадь (м²)", value: $viewModel.area, unit: "м²")
                        .onChange(of: viewModel.area) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    ParameterRow(title: "Комнаты", value: $viewModel.rooms, unit: "шт.")
                        .onChange(of: viewModel.rooms) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    ParameterRow(title: "Санузлы", value: $viewModel.bathrooms, unit: "шт.")
                        .onChange(of: viewModel.bathrooms) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    ParameterRow(title: "Парковочные места", value: $viewModel.garage, unit: "шт.")
                        .onChange(of: viewModel.garage) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    ParameterRow(title: "Расстояние до центра", value: $viewModel.distance, unit: "км")
                        .onChange(of: viewModel.distance) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    ParameterRow(title: "Этаж", value: $viewModel.floor, unit: "эт.")
                        .onChange(of: viewModel.floor) { _ in
                            viewModel.debouncedCalculate()
                        }
                    
                    Picker("Год постройки", selection: $viewModel.buildYear) {
                        ForEach(1990...2025, id: \.self) { year in
                            let yearString = String(year)
                            Text(yearString).tag(yearString)
                        }
                    }
                    .onChange(of: viewModel.buildYear) { _ in
                        viewModel.debouncedCalculate()
                    }
                    
                    Picker("Балкон", selection: $viewModel.balcony) {
                        Text("Нет").tag(0)
                        Text("Есть").tag(1)
                    }
                    .onChange(of: viewModel.balcony) { _ in
                        viewModel.debouncedCalculate()
                    }
                    
                    Picker("Ремонт", selection: $viewModel.renovation) {
                        Text("Нет").tag(0)
                        Text("Косметический").tag(1)
                        Text("Евроремонт").tag(2)
                    }
                    .onChange(of: viewModel.renovation) { _ in
                        viewModel.debouncedCalculate()
                    }
                }
                
                // MARK: - Секция 2: Условия ипотеки
                Section("Условия ипотеки") {
                    VStack(alignment: .leading) {
                        Text("Первоначальный взнос: \(Int(viewModel.downPayment))%")
                        Slider(value: $viewModel.downPayment, in: 10...50, step: 5) { _ in
                            viewModel.recalculateMortgageOnly()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Срок кредита: \(Int(viewModel.loanTerm)) лет")
                        Slider(value: $viewModel.loanTerm, in: 5...30, step: 1) { _ in
                            viewModel.recalculateMortgageOnly()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Процентная ставка: \(viewModel.interestRate, specifier: "%.1f")%")
                        Slider(value: $viewModel.interestRate, in: 3...15, step: 0.1) { _ in
                            viewModel.recalculateMortgageOnly()
                        }
                    }
                }
                
                // MARK: - Секция 3: Результаты
                Section("Результаты расчета") {
                    if viewModel.isCalculating {
                        HStack {
                            ProgressView()
                            Text("Рассчитываем...")
                                .foregroundColor(.gray)
                        }
                    } else if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    } else if let price = viewModel.predictedPrice {
                        PredictionResultView(
                            price: price,
                            monthlyPayment: viewModel.monthlyPayment,
                            downPayment: viewModel.downPayment,
                            loanTerm: viewModel.loanTerm,
                            interestRate: viewModel.interestRate
                        )
                        
                        if !viewModel.paymentChartData.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("График платежа от срока")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Chart {
                                    ForEach(viewModel.paymentChartData) { point in
                                        LineMark(
                                            x: .value("Срок (лет)", point.term),
                                            y: .value("Платёж, ₽", point.payment)
                                        )
                                    }
                                    
                                    if let currentPayment = viewModel.monthlyPayment {
                                        PointMark(
                                            x: .value("Срок (лет)", Int(viewModel.loanTerm)),
                                            y: .value("Платёж, ₽", currentPayment)
                                        )
                                        .foregroundStyle(.red)
                                        .symbolSize(80)
                                    }
                                }
                                .frame(height: 200)
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        Text("Введите параметры для расчета")
                            .foregroundColor(.gray)
                    }
                }
                
                // MARK: - Секция 4: История расчетов
                Section(header: Text("История")) {
                    if viewModel.history.isEmpty {
                        Text("История пуста")
                            .foregroundColor(.gray)
                    } else {
                        Button("Очистить историю", role: .destructive) {
                            viewModel.clearHistory()
                        }
                        
                        ForEach(viewModel.history) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Цена: \(Int(item.predictedPrice)) ₽, платёж: \(Int(item.monthlyPayment)) ₽")
                                    .font(.subheadline)
                                
                                Text("Срок: \(Int(item.loanTerm)) лет, взнос: \(Int(item.downPayment))%, ставка: \(String(format: "%.1f", item.interestRate))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.deleteHistory(at:))
                    }
                }
            }
            .navigationTitle("Ипотечный калькулятор")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
