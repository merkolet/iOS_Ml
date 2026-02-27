//
//  ParameterRow.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 14.02.2026.
//

import SwiftUI

/// Переиспользуемый компонент для ввода числовых параметров
/// Содержит: название, текстовое поле, единицу измерения
struct ParameterRow: View {
    
    let title: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
            
            Spacer()
            
            TextField("", text: $value)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .keyboardType(.decimalPad) // Цифровая клавиатура с точкой
            
            Text(unit)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
struct ParameterRow_Previews: PreviewProvider {
    
    @State static var previewValue = "75"
    
    static var previews: some View {
        List {
            ParameterRow(
                title: "Площадь (м²)",
                value: $previewValue,
                unit: "м²"
            )
        }
    }
}
