import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CounterDropLocation: Equatable {
    let collectionID: UUID?
    let index: Int
}

/// One drop surface per folder section — tracks insertion index from drag position (Shortcuts-style gaps).
@MainActor
final class CounterSectionDropDelegate: DropDelegate {
    let collectionID: UUID?
    let counterCount: Int
    let rowStride: CGFloat
    let topInset: CGFloat
    @Binding var dragOverIndex: CounterDropLocation?
    let onPerformDrop: (Int) -> Void

    private var lastInsertionIndex: Int?

    init(
        collectionID: UUID?,
        counterCount: Int,
        rowStride: CGFloat,
        topInset: CGFloat,
        dragOverIndex: Binding<CounterDropLocation?>,
        onPerformDrop: @escaping (Int) -> Void
    ) {
        self.collectionID = collectionID
        self.counterCount = counterCount
        self.rowStride = rowStride
        self.topInset = topInset
        self._dragOverIndex = dragOverIndex
        self.onPerformDrop = onPerformDrop
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateInsertionIndex(for: info.location)
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        updateInsertionIndex(for: info.location)
    }

    func dropExited(info: DropInfo) {
        if dragOverIndex?.collectionID == collectionID {
            dragOverIndex = nil
        }
        lastInsertionIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        onPerformDrop(insertionIndex(for: info.location))
        dragOverIndex = nil
        lastInsertionIndex = nil
        return true
    }

    private func updateInsertionIndex(for location: CGPoint) {
        let index = insertionIndex(for: location)
        guard index != lastInsertionIndex else { return }
        lastInsertionIndex = index
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            dragOverIndex = CounterDropLocation(collectionID: collectionID, index: index)
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func insertionIndex(for location: CGPoint) -> Int {
        let adjustedY = max(0, location.y - topInset)
        let raw = Int((adjustedY / rowStride).rounded(.down))
        return min(max(raw, 0), counterCount)
    }
}
