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
        Color.clear
            .frame(height: height)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.01, anchor: .center),
                removal: .identity
            ))
    }
}
