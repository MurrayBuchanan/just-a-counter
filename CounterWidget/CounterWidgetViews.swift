//
//  CounterWidgetViews.swift
//  CounterWidget
//

import AppIntents
import SwiftUI
import WidgetKit

struct CounterWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CounterEntry

    var body: some View {
        Group {
            if let counter = entry.counter {
                CounterWidgetContentView(counter: counter, family: family)
            } else {
                CounterWidgetEmptyView(family: family)
            }
        }
    }
}

struct CounterWidgetContentView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let counter: CounterSnapshot
    let family: WidgetFamily

    private var isMedium: Bool { family == .systemMedium }

    private var contentPadding: CGFloat { isMedium ? 16 : 14 }

    private var valueFontSize: CGFloat { isMedium ? 52 : 40 }

    private var controlHeight: CGFloat { isMedium ? 40 : 34 }

    var body: some View {
        let theme = ThemeManager.theme(for: counter.themeName)
        let step = max(counter.step, 1)
        let entity = CounterEntity(id: counter.id, name: counter.name)

        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: isMedium ? 10 : 6)

            valueSection

            Spacer(minLength: isMedium ? 10 : 6)

            CounterWidgetControlStrip(
                height: controlHeight,
                minusIntent: AdjustCounterIntent(counter: entity, delta: -step),
                plusIntent: AdjustCounterIntent(counter: entity, delta: step)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
        .containerBackground(for: .widget) {
            theme.gradient
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: counter.iconName ?? "number.circle")
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)

            Text(counter.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(labelColor)
    }

    private var valueSection: some View {
        VStack(spacing: 3) {
            Text(counter.value, format: .number)
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .foregroundStyle(valueColor)
                .frame(maxWidth: .infinity)

            if let goal = counter.goalValue {
                Text("of \(goal, format: .number)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(labelColor.opacity(0.72))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var labelColor: Color {
        renderingMode == .fullColor ? .white.opacity(0.92) : .primary.opacity(0.72)
    }

    private var valueColor: Color {
        renderingMode == .fullColor ? .white : .primary
    }
}

struct CounterWidgetControlStrip<MinusIntent: AppIntent, PlusIntent: AppIntent>: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let height: CGFloat
    let minusIntent: MinusIntent
    let plusIntent: PlusIntent

    var body: some View {
        HStack(spacing: 0) {
            CounterWidgetControlSegment(
                systemImage: "minus",
                intent: minusIntent,
                height: height
            )

            divider

            CounterWidgetControlSegment(
                systemImage: "plus",
                intent: plusIntent,
                height: height
            )
        }
        .background(controlBackground, in: Capsule())
        .frame(maxWidth: .infinity)
        .widgetAccentable()
    }

    @ViewBuilder
    private var divider: some View {
        if renderingMode == .fullColor {
            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(width: 0.5, height: height * 0.5)
        } else {
            Divider()
                .frame(height: height * 0.5)
        }
    }

    private var controlBackground: some ShapeStyle {
        if renderingMode == .fullColor {
            AnyShapeStyle(.white.opacity(0.18))
        } else {
            AnyShapeStyle(.quaternary)
        }
    }
}

struct CounterWidgetControlSegment<I: AppIntent>: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let systemImage: String
    let intent: I
    let height: CGFloat

    var body: some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(renderingMode == .fullColor ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .widgetAccentable()
    }
}

struct CounterWidgetEmptyView: View {
    let family: WidgetFamily

    private var isMedium: Bool { family == .systemMedium }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "number.circle")
                .font(isMedium ? .largeTitle : .title)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            Text("Select Counter")
                .font(isMedium ? .subheadline.weight(.medium) : .caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isMedium ? 16 : 14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
