//
//  CounterFolderSectionView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct CounterFolderSectionView: View {
    let title: String
    let collection: CounterCollection?
    let counters: [Counter]
    let allCounters: [Counter]
    let isReorderingEnabled: Bool
    let counterRowStride: CGFloat
    let folderSectionTopInset: CGFloat

    @Binding var draggingCounter: Counter?
    @Binding var draggingCollection: CounterCollection?
    @Binding var dragOverIndex: CounterDropLocation?

    var onEditCounter: (Counter) -> Void
    var onDeleteCounter: (Counter) -> Void
    var onEditCollection: ((CounterCollection) -> Void)?
    var onDeleteCollection: ((CounterCollection) -> Void)?
    var onBeginCounterDrag: (Counter, Int) -> Void
    var onEndDragSession: (Bool) -> Void

    private var collectionID: UUID? { collection?.uuid }

    private var isDraggingFromThisSection: Bool {
        guard let draggingCounter else { return false }
        if let collection {
            return draggingCounter.collection === collection
        }
        return draggingCounter.collection == nil
    }

    /// Excludes the dragged counter so its slot collapses while reordering.
    private var displayCounters: [Counter] {
        guard isDraggingFromThisSection else { return counters }
        return counters.filter { $0.uuid != draggingCounter!.uuid }
    }

    private var draggedSourceIndex: Int? {
        guard isDraggingFromThisSection else { return nil }
        return counters.firstIndex(where: { $0.uuid == draggingCounter!.uuid })
    }

    private var dropTargetCounterCount: Int {
        isDraggingFromThisSection ? displayCounters.count : counters.count
    }

    private func isDraggedAway(_ counter: Counter) -> Bool {
        draggingCounter?.uuid == counter.uuid
            && isDraggingFromThisSection
            && dragOverIndex != nil
    }

    private func visibleInsertionIndex(forFullIndex index: Int) -> Int {
        guard let source = draggedSourceIndex else { return index }
        if index <= source { return index }
        return index - 1
    }

    private func shouldShowDivider(afterIndex index: Int) -> Bool {
        guard index < counters.count - 1 else { return false }
        return !isDraggedAway(counters[index]) && !isDraggedAway(counters[index + 1])
    }

    var body: some View {
        Section {
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 6)
                VStack(spacing: 8) {
                    ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                        let draggedAway = isDraggedAway(counter)

                        if showsInsertionGap(before: visibleInsertionIndex(forFullIndex: idx)) {
                            ReorderInsertionGap(height: counterRowStride)
                        }
                        DraggableCounterRow(
                            counter: counter,
                            isReorderingEnabled: isReorderingEnabled,
                            onDragStart: {
                                let index = counters.firstIndex(where: { $0.uuid == counter.uuid }) ?? 0
                                onBeginCounterDrag(counter, index)
                            },
                            onEdit: { onEditCounter(counter) },
                            onDelete: { onDeleteCounter(counter) }
                        )
                        .frame(maxHeight: draggedAway ? 0 : nil)
                        .opacity(draggedAway ? 0 : 1)
                        .clipped()
                        .allowsHitTesting(!draggedAway)
                        .accessibilityHidden(draggedAway)
                        if shouldShowDivider(afterIndex: idx) {
                            Divider()
                                .padding(.leading, CounterRowMetrics.titleLeadingInset)
                        }
                    }
                    if showsInsertionGap(before: displayCounters.count) {
                        ReorderInsertionGap(height: counterRowStride)
                    }
                }
                .frame(minHeight: displayCounters.isEmpty && isReorderingEnabled ? counterRowStride : 0)
            }
            .contentShape(Rectangle())
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: draggingCounter?.uuid)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: dragOverIndex)
            .modifier(CounterSectionDropModifier(
                enabled: isReorderingEnabled,
                collectionID: collectionID,
                counterCount: dropTargetCounterCount,
                rowStride: counterRowStride,
                topInset: folderSectionTopInset,
                dragOverIndex: $dragOverIndex,
                shouldAcceptDrop: { draggingCounter != nil },
                onPerformDrop: { index in
                    guard let draggingCounter else {
                        onEndDragSession(false)
                        return
                    }
                    CounterReorder.moveCounter(
                        draggingCounter,
                        to: collection,
                        at: index,
                        allCounters: allCounters
                    )
                    onEndDragSession(true)
                }
            ))
        } header: {
            FolderSectionHeaderView(
                title: title,
                collection: collection,
                counters: counters,
                isReorderingEnabled: isReorderingEnabled,
                isDragging: collection.map { draggingCollection?.uuid == $0.uuid } ?? false,
                isCounterDragActive: draggingCounter != nil,
                onDropRejected: { onEndDragSession(false) },
                onDragStart: collection.map { col in
                    { draggingCounter = nil; draggingCollection = col }
                },
                onEdit: collection.flatMap { col in onEditCollection.map { edit in { edit(col) } } },
                onDelete: collection.flatMap { col in onDeleteCollection.map { delete in { delete(col) } } }
            )
        }
    }

    private func showsInsertionGap(before index: Int) -> Bool {
        draggingCounter != nil
            && dragOverIndex?.collectionID == collectionID
            && dragOverIndex?.index == index
    }
}
