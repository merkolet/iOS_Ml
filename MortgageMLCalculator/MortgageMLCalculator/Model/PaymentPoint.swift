//
//  PaymentPoint.swift
//  MortgageMLCalculator
//
//  Created by Sergey on 26.02.2026.
//

import SwiftUI

struct PaymentPoint: Identifiable {
    let id = UUID()
    let term: Int
    let payment: Double
}
