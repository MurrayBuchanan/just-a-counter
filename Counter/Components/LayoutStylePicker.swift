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
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.tertiarySystemFill))

                if UIImage(named: style.imageName) != nil {
                    Image(style.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: style.systemImage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
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
