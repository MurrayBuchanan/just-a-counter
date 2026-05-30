//
//  CounterWidgetViews.swift
//  CounterWidget
//

import SwiftUI
import WidgetKit

struct CounterWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CounterEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallCounterWidgetView(counter: entry.counter)
            case .systemMedium:
                MediumCounterWidgetView(counter: entry.counter)
            default:
                SmallCounterWidgetView(counter: entry.counter)
            }
        }
        .foregroundStyle(.white)
    }
}

struct SmallCounterWidgetView: View {
    let counter: CounterSnapshot?

    var body: some View {
        if let counter {
            let theme = ThemeManager.theme(for: counter.themeName)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: counter.iconName ?? "circle")
                        .font(.headline)
                    Text(counter.name)
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text("\(counter.value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if let goal = counter.goalValue {
                    Text("Goal \(goal)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .containerBackground(theme.gradient, for: .widget)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "number.circle")
                    .font(.title2)
                Text("Edit widget to choose a counter")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct MediumCounterWidgetView: View {
    let counter: CounterSnapshot?

    var body: some View {
        if let counter {
            let theme = ThemeManager.theme(for: counter.themeName)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: counter.iconName ?? "circle")
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(counter.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(counter.value)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    if let goal = counter.goalValue, goal > 0 {
                        ProgressView(value: Double(min(counter.value, goal)), total: Double(goal))
                            .tint(.white)
                        Text("\(counter.value) / \(goal)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .containerBackground(theme.gradient, for: .widget)
        } else {
            HStack(spacing: 12) {
                Image(systemName: "number.circle")
                    .font(.largeTitle)
                Text("Edit widget to choose a counter")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
