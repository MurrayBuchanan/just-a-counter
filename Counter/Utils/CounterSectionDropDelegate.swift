//
//  CounterSectionDropDelegate.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UIKit

struct CounterDropLocation: Equatable {
    let collectionID: UUID?
    let index: Int
}

/// Rejects counter drops on section headers so they cannot replace the title as a target.
@MainActor
final class CounterHeaderDropBlockDelegate: DropDelegate {
    let onDropOnHeader: () -> Void

    init(onDropOnHeader: @escaping () -> Void) {
        self.onDropOnHeader = onDropOnHeader
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        onDropOnHeader()
        return false
    }
}

/// Tracks insertion index from drag position within a folder section (Shortcuts-style gaps).
@MainActor
final class CounterSectionDropDelegate: DropDelegate {
    let collectionID: UUID?
    let counterCount: Int
    let rowStride: CGFloat
    @Binding var dragOverIndex: CounterDropLocation?
    let onPerformDrop: (Int) -> Void
    let onInvalidDrop: () -> Void

    private var lastInsertionIndex: Int?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    init(
        collectionID: UUID?,
        counterCount: Int,
        rowStride: CGFloat,
        dragOverIndex: Binding<CounterDropLocation?>,
        onPerformDrop: @escaping (Int) -> Void,
        onInvalidDrop: @escaping () -> Void
    ) {
        self.collectionID = collectionID
        self.counterCount = counterCount
        self.rowStride = rowStride
        self._dragOverIndex = dragOverIndex
        self.onPerformDrop = onPerformDrop
        self.onInvalidDrop = onInvalidDrop
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateInsertionIndex(for: info.location)
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        feedbackGenerator.prepare()
        updateInsertionIndex(for: info.location)
    }

    func dropExited(info: DropInfo) {
        if dragOverIndex?.collectionID == collectionID {
            dragOverIndex = nil
        }
        lastInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            dragOverIndex = nil
            lastInsertionIndex = nil
        }
        let index = dragOverIndex?.collectionID == collectionID
            ? dragOverIndex!.index
            : insertionIndex(for: info.location)
        onPerformDrop(index)
        return true
    }

    private func updateInsertionIndex(for location: CGPoint) {
        let index = insertionIndex(for: location)
        guard index != lastInsertionIndex else { return }
        lastInsertionIndex = index
        withAnimation(.snappy) {
            dragOverIndex = CounterDropLocation(collectionID: collectionID, index: index)
        }
        feedbackGenerator.impactOccurred()
    }

    private func insertionIndex(for location: CGPoint) -> Int {
        let raw = Int((max(0, location.y) / rowStride).rounded())
        return min(max(raw, 0), counterCount)
    }
}

/// Reorders folder headers when dragging one folder onto another position in the list.
@MainActor
final class CollectionSectionDropDelegate: DropDelegate {
    let collectionCount: Int
    let rowStride: CGFloat
    @Binding var dragOverCollectionIndex: Int?
    let onPerformDrop: (Int) -> Void

    private var lastInsertionIndex: Int?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    init(
        collectionCount: Int,
        rowStride: CGFloat,
        dragOverCollectionIndex: Binding<Int?>,
        onPerformDrop: @escaping (Int) -> Void
    ) {
        self.collectionCount = collectionCount
        self.rowStride = rowStride
        self._dragOverCollectionIndex = dragOverCollectionIndex
        self.onPerformDrop = onPerformDrop
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateInsertionIndex(for: info.location)
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        feedbackGenerator.prepare()
        updateInsertionIndex(for: info.location)
    }

    func dropExited(info: DropInfo) {
        dragOverCollectionIndex = nil
        lastInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        let index = dragOverCollectionIndex ?? insertionIndex(for: info.location)
        onPerformDrop(index)
        dragOverCollectionIndex = nil
        lastInsertionIndex = nil
        return true
    }

    private func updateInsertionIndex(for location: CGPoint) {
        let index = insertionIndex(for: location)
        guard index != lastInsertionIndex else { return }
        lastInsertionIndex = index
        withAnimation(.snappy) {
            dragOverCollectionIndex = index
        }
        feedbackGenerator.impactOccurred()
    }

    private func insertionIndex(for location: CGPoint) -> Int {
        let raw = Int((max(0, location.y) / rowStride).rounded())
        return min(max(raw, 0), collectionCount)
    }
}
