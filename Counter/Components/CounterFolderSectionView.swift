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
    @Binding var dragOverSection: UUID?
    @Binding var isUnassignedHeaderDropTarget: Bool

    var onEditCounter: (Counter) -> Void
    var onDeleteCounter: (Counter) -> Void
    var onEditCollection: ((CounterCollection) -> Void)?
    var onDeleteCollection: ((CounterCollection) -> Void)?
    var onCounterDrop: (CounterCollection?, Int, [NSItemProvider]) -> Void
    var onEndDragSession: () -> Void

    private var collectionID: UUID? { collection?.uuid }

    var body: some View {
        Section {
            Divider()
                .padding(.bottom, 6)
            VStack(spacing: 8) {
                ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                    if showsInsertionGap(before: idx) {
                        ReorderInsertionGap()
                    }
                    DraggableCounterRow(
                        counter: counter,
                        isDragging: draggingCounter?.uuid == counter.uuid,
                        isReorderingEnabled: isReorderingEnabled,
                        onDragStart: {
                            draggingCollection = nil
                            draggingCounter = counter
                        },
                        onEdit: { onEditCounter(counter) },
                        onDelete: { onDeleteCounter(counter) }
                    )
                }
                if showsInsertionGap(before: counters.count) {
                    ReorderInsertionGap()
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: dragOverIndex)
            .modifier(CounterSectionDropModifier(
                enabled: isReorderingEnabled,
                collectionID: collectionID,
                counterCount: counters.count,
                rowStride: counterRowStride,
                topInset: folderSectionTopInset,
                dragOverIndex: $dragOverIndex,
                shouldAcceptDrop: { draggingCounter != nil },
                onPerformDrop: { index in
                    guard let draggingCounter else {
                        onEndDragSession()
                        return
                    }
                    let adjusted = CounterReorder.adjustedInsertionIndex(
                        for: draggingCounter,
                        in: collection,
                        proposed: index,
                        destinationCounters: counters
                    )
                    CounterReorder.moveCounter(
                        draggingCounter,
                        to: collection,
                        at: adjusted,
                        allCounters: allCounters
                    )
                    onEndDragSession()
                }
            ))
        } header: {
            FolderSectionHeaderView(
                title: title,
                collection: collection,
                counters: counters,
                isReorderingEnabled: isReorderingEnabled,
                isDragging: collection.map { draggingCollection?.uuid == $0.uuid } ?? false,
                isTargeted: headerDropTargetBinding,
                onDrop: isReorderingEnabled ? { providers in
                    onCounterDrop(collection, counters.count, providers)
                    return true
                } : nil,
                onDragStart: collection.map { col in
                    { draggingCounter = nil; draggingCollection = col }
                },
                onEdit: collection.flatMap { col in onEditCollection.map { edit in { edit(col) } } },
                onDelete: collection.flatMap { col in onDeleteCollection.map { delete in { delete(col) } } }
            )
        }
    }

    private var headerDropTargetBinding: Binding<Bool> {
        if collectionID == nil {
            return $isUnassignedHeaderDropTarget
        }
        return Binding(
            get: { dragOverSection == collectionID },
            set: { isTargeted in dragOverSection = isTargeted ? collectionID : nil }
        )
    }

    private func showsInsertionGap(before index: Int) -> Bool {
        draggingCounter != nil
            && dragOverIndex?.collectionID == collectionID
            && dragOverIndex?.index == index
    }
}
