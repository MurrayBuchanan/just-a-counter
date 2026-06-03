//
//  CounterDropModifiers.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

/// Prevents counter drops from landing on section titles; insertion uses the list below.
struct CounterHeaderDropBlockModifier: ViewModifier {
    let active: Bool
    let onDropOnHeader: () -> Void

    func body(content: Content) -> some View {
        if active {
            content.onDrop(
                of: [.text],
                delegate: CounterHeaderDropBlockDelegate(onDropOnHeader: onDropOnHeader)
            )
        } else {
            content
        }
    }
}

struct CounterSectionDropModifier: ViewModifier {
    let enabled: Bool
    let collectionID: UUID?
    let counterCount: Int
    let rowStride: CGFloat
    @Binding var dragOverIndex: CounterDropLocation?
    let shouldAcceptDrop: () -> Bool
    let onPerformDrop: (Int) -> Void
    let onInvalidDrop: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled, shouldAcceptDrop() {
            content.onDrop(
                of: [.text],
                delegate: CounterSectionDropDelegate(
                    collectionID: collectionID,
                    counterCount: counterCount,
                    rowStride: rowStride,
                    dragOverIndex: $dragOverIndex,
                    onPerformDrop: onPerformDrop,
                    onInvalidDrop: onInvalidDrop
                )
            )
        } else {
            content
        }
    }
}

struct CollectionSectionDropModifier: ViewModifier {
    let enabled: Bool
    let collectionCount: Int
    let rowStride: CGFloat
    @Binding var dragOverCollectionIndex: Int?
    let shouldAcceptDrop: () -> Bool
    let onPerformDrop: (Int) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled, shouldAcceptDrop() {
            content.onDrop(
                of: [.text],
                delegate: CollectionSectionDropDelegate(
                    collectionCount: collectionCount,
                    rowStride: rowStride,
                    dragOverCollectionIndex: $dragOverCollectionIndex,
                    onPerformDrop: onPerformDrop
                )
            )
        } else {
            content
        }
    }
}
