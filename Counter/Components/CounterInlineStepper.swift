//
//  CounterInlineStepper.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import SwiftUI

/// Compact − / + control matching the capsule UIStepper silhouette in system lists.
struct CounterInlineStepper: View {
    @Binding var value: Int
    let step: Int
    let range: ClosedRange<Int>
    var counterName: String = ""
    var onValueChange: (() -> Void)?

    private var stepAmount: Int { max(step, 1) }

    private var stepperAccessibilityLabel: String {
        counterName.isEmpty ? "Adjust value" : "Adjust \(counterName)"
    }

    /// Apple HIG minimum; visual capsule stays smaller inside this footprint.
    private let hitSize: CGFloat = 44
    private let capsuleHeight: CGFloat = 32

    var body: some View {
        HStack(spacing: 0) {
            stepButton(
                systemName: "minus",
                accessibilityLabel: "Decrease",
                accessibilityHint: CounterAccessibility.stepperDecreaseHint(step: stepAmount),
                isEnabled: value > range.lowerBound
            ) {
                value = CounterValueBounds.clamp(value - stepAmount)
                onValueChange?()
            }
            separator
            stepButton(
                systemName: "plus",
                accessibilityLabel: "Increase",
                accessibilityHint: CounterAccessibility.stepperIncreaseHint(step: stepAmount),
                isEnabled: value < range.upperBound
            ) {
                value = CounterValueBounds.clamp(value + stepAmount)
                onValueChange?()
            }
        }
        .background {
            Capsule()
                .fill(Color(.tertiarySystemFill))
                .frame(height: capsuleHeight)
        }
        .frame(height: hitSize)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(stepperAccessibilityLabel)
        .accessibilityValue(CounterValueFormatting.formattedValue(value))
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1 / UIScreen.main.scale, height: 18)
    }

    private func stepButton(
        systemName: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: hitSize, height: hitSize)
        .foregroundStyle(isEnabled ? .primary : .tertiary)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
}
