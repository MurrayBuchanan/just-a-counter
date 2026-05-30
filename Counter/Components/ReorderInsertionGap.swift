//
//  ReorderInsertionGap.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct ReorderInsertionGap: View {
    let height: CGFloat

    init(height: CGFloat) {
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 2)
            )
            .frame(height: height)
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .center)))
    }
}
