//
//  CounterValueFormatting.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import Foundation

enum CounterValueFormatting {
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func formattedValue(_ value: Int) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func listRowValue(value: Int, goal: Int?) -> String {
        let valueText = formattedValue(value)
        guard let goal else { return valueText }
        return "\(valueText) / \(formattedValue(goal))"
    }
}
