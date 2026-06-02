//
//  CounterRowView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UIKit

enum CounterRowMetrics {
    static let iconSize: CGFloat = 40
    static let iconToTitleSpacing: CGFloat = 10
    static let rowStride: CGFloat = 64
    static var titleLeadingInset: CGFloat { iconSize + iconToTitleSpacing }
}

struct CounterRowView: View {
    @Bindable var counter: Counter
    @State private var isActive = false

    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: CounterRowMetrics.iconToTitleSpacing) {
                ZStack {
                    Circle()
                        .fill(theme.gradient)
                        .frame(
                            width: CounterRowMetrics.iconSize,
                            height: CounterRowMetrics.iconSize
                        )
                    Image(systemName: counter.iconName ?? "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(counter.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("\(counter.value)")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    if let goal = counter.goalValue {
                        Text("/ \(goal)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isActive = true
            }

            Stepper(
                value: $counter.value,
                in: CounterValueBounds.range,
                step: max(counter.step, 1)
            ) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: counter.value) { _, _ in
                counter.lastUpdated = Date()
                WidgetReloader.scheduleReload(for: counter)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: counter.value)
        .background(
            NavigationLink(destination: CounterView(counter: counter), isActive: $isActive) {
                EmptyView()
            }
            .opacity(0)
        )
    }
}

#Preview {
    let counter = Counter(name: "Push-ups", value: 42, step: 1)
    return CounterRowView(counter: counter)
}
