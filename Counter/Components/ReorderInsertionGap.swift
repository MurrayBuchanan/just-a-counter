//
//  ReorderInsertionGap.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct ReorderInsertionGap: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.5))
            .frame(height: 3)
            .padding(.vertical, 2)
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .center)))
    }
}
