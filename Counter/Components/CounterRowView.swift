//
//  CounterRowView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UIKit

enum CounterRowMetrics {
    static let iconSize: CGFloat = 28
    static let iconToTitleSpacing: CGFloat = 12
    static let textLineSpacing: CGFloat = 2
    static let rowHeight: CGFloat = 58
    static let rowStride: CGFloat = 58
    static let stepperWidth: CGFloat = 88
    static var titleLeadingInset: CGFloat { iconSize + iconToTitleSpacing }
}

struct CounterRowView: View {
    @Bindable var counter: Counter
    @State private var isActive = false

    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }

    private var valueLabel: String {
        CounterValueFormatting.listRowValue(value: counter.value, goal: counter.goalValue)
    }

    private var accessibilitySummary: String {
        CounterAccessibility.listRowLabel(
            name: counter.name,
            value: counter.value,
            goal: counter.goalValue,
            isLocked: counter.isLocked
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: counter.iconName ?? "circle")
                .font(.body.weight(.medium))
                .imageScale(.large)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(theme.primaryColor)
                .frame(width: CounterRowMetrics.iconSize, alignment: .center)
                .accessibilityHidden(true)

            Button {
                isActive = true
            } label: {
                VStack(alignment: .leading, spacing: CounterRowMetrics.textLineSpacing) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(counter.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if counter.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.tertiary)
                                .symbolRenderingMode(.hierarchical)
                                .fixedSize()
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(valueLabel)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint(CounterAccessibility.listRowHint(isLocked: counter.isLocked))

            if !counter.isLocked {
                trailingStepper
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
            }
        }
        .frame(minHeight: CounterRowMetrics.rowHeight)
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: counter.value)
        .animation(.easeInOut(duration: 0.2), value: counter.isLocked)
        .background(
            NavigationLink(destination: CounterView(counter: counter), isActive: $isActive) {
                EmptyView()
            }
            .opacity(0)
        )
    }

    private var trailingStepper: some View {
        CounterInlineStepper(
            value: $counter.value,
            step: counter.step,
            range: CounterValueBounds.range,
            counterName: counter.name,
            onValueChange: {
                counter.lastUpdated = Date()
                WidgetReloader.scheduleReload(for: counter)
            }
        )
        .frame(width: CounterRowMetrics.stepperWidth)
    }
}

#Preview("Unlocked") {
    CounterRowView(counter: Counter(name: "Winning Streak", value: 110_182, step: 1))
}

#Preview("Locked") {
    CounterRowView(counter: Counter(name: "Olivia", value: 154, step: 1, iconName: "plus.square.fill", isLocked: true))
}
