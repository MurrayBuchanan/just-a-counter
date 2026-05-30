//
//  CounterDropModifiers.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct CounterSectionDropModifier: ViewModifier {
    let enabled: Bool
    let collectionID: UUID?
    let counterCount: Int
    let rowStride: CGFloat
    let topInset: CGFloat
    @Binding var dragOverIndex: CounterDropLocation?
    let shouldAcceptDrop: () -> Bool
    let onPerformDrop: (Int) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.onDrop(
                of: [.text],
                delegate: CounterSectionDropDelegate(
                    collectionID: collectionID,
                    counterCount: counterCount,
                    rowStride: rowStride,
                    topInset: topInset,
                    dragOverIndex: $dragOverIndex,
                    shouldAcceptDrop: shouldAcceptDrop,
                    onPerformDrop: onPerformDrop
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

    func body(content: Content) -> some View {
        if enabled {
            content.onDrop(
                of: [.text],
                delegate: CollectionSectionDropDelegate(
                    collectionCount: collectionCount,
                    rowStride: rowStride,
                    dragOverCollectionIndex: $dragOverCollectionIndex,
                    shouldAcceptDrop: shouldAcceptDrop,
                    onPerformDrop: onPerformDrop
                )
            )
        } else {
            content
        }
    }
}
