//
//  CounterAccessibility.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import Foundation

enum CounterAccessibility {
    static func listRowLabel(name: String, value: Int, goal: Int?, isLocked: Bool) -> String {
        let valuePhrase = listRowValuePhrase(value: value, goal: goal)
        if isLocked {
            return "\(name), \(valuePhrase), locked"
        }
        return "\(name), \(valuePhrase)"
    }

    static func listRowHint(isLocked: Bool) -> String {
        isLocked ? "Opens counter details. Value cannot be changed while locked." : "Opens counter details."
    }

    static func stepperDecreaseHint(step: Int) -> String {
        "Subtracts \(step) from the current value."
    }

    static func stepperIncreaseHint(step: Int) -> String {
        "Adds \(step) to the current value."
    }

    private static func listRowValuePhrase(value: Int, goal: Int?) -> String {
        let formatted = CounterValueFormatting.formattedValue(value)
        guard let goal else {
            return formatted
        }
        return "\(formatted) of \(CounterValueFormatting.formattedValue(goal))"
    }
}
