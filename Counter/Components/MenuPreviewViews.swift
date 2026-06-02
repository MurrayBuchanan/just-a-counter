//
//  MenuPreviewViews.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

extension View {
    /// Kept for drag previews only — list rows use section-level grouping instead.
    func counterRowCardBackground() -> some View {
        counterSectionGroupedBackground()
    }
}
