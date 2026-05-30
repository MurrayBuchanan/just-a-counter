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
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 64)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    selection == style ? Color.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.rawValue.capitalized)
            }
        }
        .padding(.vertical, 4)
    }
}
