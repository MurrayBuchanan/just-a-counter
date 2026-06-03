//
//  CounterGroupedListStyle.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import SwiftUI
import UIKit

enum CounterGroupedListStyle {
    /// Inset grouped folder card — iOS 26 uses noticeably rounder corners than older releases.
    static let sectionCornerRadius: CGFloat = 20
    static let horizontalInset: CGFloat = 16
    /// Inset grouped: space above each section header after the first (card → next header).
    static let sectionSpacing: CGFloat = 20
    /// Space from section header to the rounded card (Notes-style grouping).
    static let headerToContentSpacing: CGFloat = 8
    static let scrollTopContentMargin: CGFloat = 4
    static let sectionHeaderMinHeight: CGFloat = 36
    static let rowHorizontalPadding: CGFloat = 16

    /// Leading inset for dividers inside a group (aligned with row text, after the icon).
    static var rowSeparatorLeadingInset: CGFloat {
        rowHorizontalPadding + CounterRowMetrics.titleLeadingInset
    }

    /// Fill for grouped “cards” — elevated gray on black in dark mode, like Notes.
    static var sectionCardFill: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

extension Text {
    /// Notes-style folder headers: bold primary title above each group.
    func counterFolderSectionHeaderStyle() -> some View {
        font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .textCase(nil)
    }
}

extension View {
    /// Single rounded container for all rows in a folder (Notes list group).
    func counterSectionGroupedBackground() -> some View {
        let shape = RoundedRectangle(cornerRadius: CounterGroupedListStyle.sectionCornerRadius, style: .continuous)
        return background(CounterGroupedListStyle.sectionCardFill, in: shape)
            .clipShape(shape)
    }

    /// Inset separator between rows inside a group (Notes-style, aligned with title text).
    @ViewBuilder
    func counterSectionInsetDivider(isVisible: Bool) -> some View {
        if isVisible {
            overlay(alignment: .bottom) {
                Divider()
                    .padding(.leading, CounterGroupedListStyle.rowSeparatorLeadingInset)
            }
        } else {
            self
        }
    }
}
