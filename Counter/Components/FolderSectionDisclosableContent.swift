//
//  FolderSectionDisclosableContent.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import SwiftUI

/// Animates section body height the way grouped UITableView sections do: clip from the top, ease with `.smooth`.
struct FolderSectionDisclosableContent<Content: View>: View {
    let isExpanded: Bool
    @ViewBuilder var content: () -> Content

    @State private var contentHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: FolderSectionContentHeightKey.self, value: geometry.size.height)
                }
            }
            .onPreferenceChange(FolderSectionContentHeightKey.self) { height in
                guard height > 0, abs(height - contentHeight) > 0.5 else { return }
                contentHeight = height
            }
            .frame(maxWidth: .infinity)
            .frame(height: isExpanded ? contentHeight : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .allowsHitTesting(isExpanded)
            .accessibilityHidden(!isExpanded)
            .animation(FolderSectionDisclosureAnimation.expandCollapse(reduceMotion: reduceMotion), value: isExpanded)
            .animation(FolderSectionDisclosureAnimation.expandCollapse(reduceMotion: reduceMotion), value: contentHeight)
    }
}

private enum FolderSectionContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
