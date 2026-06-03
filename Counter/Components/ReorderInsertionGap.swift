//
//  ReorderInsertionGap.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct ReorderInsertionGap: View {
    let height: CGFloat

    var body: some View {
        ZStack {
            Color.clear
            HStack(spacing: 0) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 7, height: 7)
                    .padding(.leading, CounterGroupedListStyle.rowHorizontalPadding - 3.5)
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.trailing, CounterGroupedListStyle.rowHorizontalPadding)
            }
        }
        .frame(height: height)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .center)),
            removal: .opacity
        ))
    }
}
