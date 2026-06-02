//
//  CounterFolderSectionView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

enum CounterFolderSectionMetrics {
    /// Divider + padding above the first counter row inside section content.
    static let contentTopInset: CGFloat = 7
}

struct CounterFolderSectionView: View {
    let title: String
    let collection: CounterCollection?
    let counters: [Counter]
    let allCounters: [Counter]
    let collections: [CounterCollection]
    let showsCounterContent: Bool
    let isExpanded: Bool
    let showsDisclosureChevron: Bool
    let isReorderingEnabled: Bool
    let counterRowStride: CGFloat
    let isDragLayoutActive: Bool

    var onToggleExpansion: (() -> Void)?

    @Binding var draggingCounterID: UUID?
    @Binding var draggingCollection: CounterCollection?
    @Binding var dragOverIndex: CounterDropLocation?

    var onEditCounter: (Counter) -> Void
    var onMoveCounter: (Counter, CounterCollection?) -> Void
    var onDuplicateCounter: (Counter) -> Void
    var onDeleteCounter: (Counter) -> Void
    var onEditCollection: ((CounterCollection) -> Void)?
    var onDeleteCollection: ((CounterCollection) -> Void)?
    var onBeginCounterDrag: (Counter, Int) -> Void
    var onEndDragSession: () -> Void

    private var collectionID: UUID? { collection?.uuid }

    private var draggedCounter: Counter? {
        guard let draggingCounterID else { return nil }
        return allCounters.first(where: { $0.uuid == draggingCounterID })
    }

    private var isDraggingFromThisSection: Bool {
        guard let draggedCounter else { return false }
        if let collection {
            return draggedCounter.collection === collection
        }
        return draggedCounter.collection == nil
    }

    /// Excludes the dragged counter from layout once the drag has entered a drop target.
    /// Keeping it visible until then prevents it disappearing during a context menu long-press.
    private var displayCounters: [Counter] {
        guard isDraggingFromThisSection, let draggingCounterID, dragOverIndex != nil else { return counters }
        return counters.filter { $0.uuid != draggingCounterID }
    }

    private var draggedSourceIndex: Int? {
        guard isDraggingFromThisSection, let draggingCounterID else { return nil }
        return counters.firstIndex(where: { $0.uuid == draggingCounterID })
    }

    private var dropTargetCounterCount: Int {
        isDraggingFromThisSection ? displayCounters.count : counters.count
    }

    /// Omits the dragged counter from layout so its slot can be replaced by an insertion gap.
    private var listCounters: [Counter] {
        isDraggingFromThisSection ? displayCounters : counters
    }

    private var showsCollapsedDropTarget: Bool {
        !showsCounterContent && isReorderingEnabled && draggingCounterID != nil
    }

    var body: some View {
        Section {
            if showsCollapsedDropTarget {
                collapsedDropTarget
            } else {
                FolderSectionDisclosableContent(isExpanded: showsCounterContent) {
                    expandedSectionContent
                }
            }
        } header: {
            FolderSectionHeaderView(
                title: title,
                collection: collection,
                counters: counters,
                isExpanded: isExpanded,
                showsDisclosureChevron: showsDisclosureChevron,
                isReorderingEnabled: isReorderingEnabled,
                isDragging: collection.map { draggingCollection?.uuid == $0.uuid } ?? false,
                isCounterDragActive: draggingCounterID != nil,
                onToggleExpansion: onToggleExpansion,
                onDropOnHeader: scheduleEndDragSession,
                onDragStart: collection.map { col in
                    {
                        draggingCounterID = nil
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            draggingCollection = col
                        }
                    }
                },
                onEdit: collection.flatMap { col in onEditCollection.map { edit in { edit(col) } } },
                onDelete: collection.flatMap { col in onDeleteCollection.map { delete in { delete(col) } } }
            )
        }
    }

    private var expandedSectionContent: some View {
        VStack(spacing: 0) {
            counterRows
        }
        .frame(minHeight: listCounters.isEmpty && isReorderingEnabled ? counterRowStride : 0)
        .counterSectionGroupedBackground()
        .contentShape(Rectangle())
        .modifier(counterSectionDropModifier(topInset: 0))
    }

    private var collapsedDropTarget: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: counterRowStride)
            .contentShape(Rectangle())
            .modifier(counterSectionDropModifier(topInset: 0))
    }

    private func counterSectionDropModifier(topInset: CGFloat) -> CounterSectionDropModifier {
        CounterSectionDropModifier(
            enabled: isReorderingEnabled,
            collectionID: collectionID,
            counterCount: dropTargetCounterCount,
            rowStride: counterRowStride,
            topInset: topInset,
            dragOverIndex: $dragOverIndex,
            shouldAcceptDrop: { draggingCounterID != nil },
            onPerformDrop: { index in
                guard let draggingCounterID,
                      let draggingCounter = allCounters.first(where: { $0.uuid == draggingCounterID }) else {
                    scheduleEndDragSession()
                    return
                }
                let destination = collection
                scheduleEndDragSession()
                DispatchQueue.main.async {
                    CounterReorder.moveCounter(
                        draggingCounter,
                        to: destination,
                        at: index,
                        allCounters: allCounters
                    )
                }
            },
            onInvalidDrop: scheduleEndDragSession
        )
    }

    @ViewBuilder
    private var counterRows: some View {
        if listCounters.isEmpty, isReorderingEnabled {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: counterRowStride)
        } else {
            ForEach(Array(listCounters.enumerated()), id: \.1.uuid) { idx, counter in
                if showsInsertionGap(before: idx) {
                    ReorderInsertionGap(height: counterRowStride)
                }
                DraggableCounterRow(
                    counter: counter,
                    collections: collections,
                    isReorderingEnabled: isReorderingEnabled,
                    onDragStart: {
                        let index = counters.firstIndex(where: { $0.uuid == counter.uuid }) ?? 0
                        onBeginCounterDrag(counter, index)
                    },
                    onEdit: { onEditCounter(counter) },
                    onMove: { onMoveCounter(counter, $0) },
                    onDuplicate: { onDuplicateCounter(counter) },
                    onDelete: { onDeleteCounter(counter) }
                )
                .frame(height: isDragLayoutActive ? counterRowStride : nil)
                if !isDragLayoutActive, idx < listCounters.count - 1 {
                    Divider()
                        .padding(.leading, 16 + CounterRowMetrics.titleLeadingInset)
                }
            }
            if showsInsertionGap(before: listCounters.count) {
                ReorderInsertionGap(height: counterRowStride)
            }
        }
    }

    private func scheduleEndDragSession() {
        DispatchQueue.main.async {
            onEndDragSession()
        }
    }

    private func showsInsertionGap(before index: Int) -> Bool {
        guard let dragOverIndex, draggingCounterID != nil, !listCounters.isEmpty else { return false }
        return dragOverIndex.collectionID == collectionID && dragOverIndex.index == index
    }
}
