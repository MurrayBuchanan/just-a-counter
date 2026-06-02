//
//  LayoutStylePicker.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct LayoutStylePicker: View {
    @Binding var selection: CounterLayoutStyle

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CounterLayoutStyle.allCases) { style in
                Button {
                    selection = style
                } label: {
                    LayoutPickerCell(style: style, isSelected: selection == style)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.displayName)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LayoutPickerCell: View {
    let style: CounterLayoutStyle
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            LayoutPlaceholder(style: style)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(height: 72)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                }

            Text(style.displayName)
                .font(.caption)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
    }
}

// MARK: - Placeholder mockups

private struct LayoutPlaceholder: View {
    let style: CounterLayoutStyle

    private var surface: Color { Color(.secondarySystemBackground) }
    private var minimalSurface: Color { Color(.tertiarySystemFill) }
    private var valueColor: Color { Color(.label) }
    private var controlFill: Color { Color(.tertiaryLabel) }
    private var controlMuted: Color { Color(.quaternaryLabel) }

    var body: some View {
        switch style {
        case .standard: standardPlaceholder
        case .wide:     widePlaceholder
        case .split:    splitPlaceholder
        case .minimal:  minimalPlaceholder
        }
    }

    // Centered value · two circles at the bottom
    private var standardPlaceholder: some View {
        ZStack {
            surface
            VStack(spacing: 0) {
                Spacer()
                Text("42")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                Spacer()
                HStack(spacing: 14) {
                    mockCircle(isPlus: false, filled: false)
                    mockCircle(isPlus: true,  filled: true)
                }
                .padding(.bottom, 10)
            }
        }
    }

    // Value in the upper half · two pill buttons in the lower half
    private var widePlaceholder: some View {
        ZStack {
            surface
            VStack(spacing: 6) {
                Text("42")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .frame(maxHeight: .infinity)
                HStack(spacing: 6) {
                    mockPill(systemImage: "minus")
                    mockPill(systemImage: "plus")
                }
                .frame(height: 22)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
    }

    // Full-width tap zones · chevrons at edges · large value
    private var splitPlaceholder: some View {
        ZStack {
            surface
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(controlMuted)
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(controlMuted)
                    .padding(.trailing, 10)
            }
            Text("42")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
        }
    }

    // Darker neutral surface · monochrome-style controls
    private var minimalPlaceholder: some View {
        ZStack {
            minimalSurface
            VStack(spacing: 0) {
                Spacer()
                Text("42")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                Spacer()
                HStack(spacing: 14) {
                    mockCircle(isPlus: false, filled: false, onMinimal: true)
                    mockCircle(isPlus: true,  filled: true,  onMinimal: true)
                }
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Micro components

    private func mockCircle(isPlus: Bool, filled: Bool, onMinimal: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(filled ? controlFill : controlMuted.opacity(onMinimal ? 0.55 : 1))
                .frame(width: 18, height: 18)
            Image(systemName: isPlus ? "plus" : "minus")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(
                    filled && onMinimal ? Color(.systemBackground) : valueColor
                )
        }
    }

    private func mockPill(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(controlMuted)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(valueColor)
            }
    }
}
