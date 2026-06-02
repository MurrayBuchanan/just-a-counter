//
//  CounterGroupedListStyle.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import SwiftUI

enum CounterGroupedListStyle {
    static let sectionCornerRadius: CGFloat = 10
    static let horizontalInset: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
}

extension View {
    /// One inset-grouped “card” wrapping all rows in a folder section (Settings / Reminders style).
    func counterSectionGroupedBackground() -> some View {
        background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: CounterGroupedListStyle.sectionCornerRadius, style: .continuous))
    }
}
