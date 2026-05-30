//
//  CountersListView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct CountersListView: View {
    let collections: [CounterCollection]
    let allCounters: [Counter]
    let searchText: String

    var onEditCounter: (Counter) -> Void
    var onDeleteCounter: (Counter) -> Void
    var onEditCollection: (CounterCollection) -> Void
    var onDeleteCollection: (CounterCollection) -> Void

    @State private var dragOverIndex: CounterDropLocation? = nil
    @State private var dragOverCollectionIndex: Int? = nil
    @State private var draggingCounter: Counter? = nil
    @State private var draggingCollection: CounterCollection? = nil
    @State private var counterDragOrigin: CounterDragOrigin? = nil

    private let counterRowStride: CGFloat = CounterRowMetrics.rowStride
    private let folderSectionTopInset: CGFloat = 10
    private let collectionHeaderStride: CGFloat = 56

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                if showsUnassignedSection {
                    unassignedSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                collectionSectionsStack
            }
            .animation(.easeInOut(duration: 0.2), value: showsUnassignedSection)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .onChange(of: dragOverIndex) { oldValue, newValue in
                guard draggingCounter != nil, oldValue != nil, newValue == nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if draggingCounter != nil, dragOverIndex == nil {
                        endDragSession(didCommit: false)
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: .constant(false), perform: { _ in
                endDragSession(didCommit: false)
                return false
            })
        }
    }

    // MARK: - Sections

    private var unassignedSection: some View {
        CounterFolderSectionView(
            title: "Unassigned",
            collection: nil,
            counters: unassignedCounters,
            allCounters: allCounters,
            isReorderingEnabled: isReorderingEnabled,
            counterRowStride: counterRowStride,
            folderSectionTopInset: folderSectionTopInset,
            draggingCounter: $draggingCounter,
            draggingCollection: $draggingCollection,
            dragOverIndex: $dragOverIndex,
            onEditCounter: onEditCounter,
            onDeleteCounter: onDeleteCounter,
            onBeginCounterDrag: { counter, index in
                beginCounterDrag(counter, in: nil, at: index)
            },
            onEndDragSession: endDragSession
        )
    }

    private var collectionSectionsStack: some View {
        VStack(spacing: 16) {
            ForEach(Array(filteredCollections.enumerated()), id: \.element.uuid) { idx, collection in
                if showsCollectionInsertionGap(before: idx) {
                    ReorderInsertionGap(height: collectionHeaderStride)
                }
                CounterFolderSectionView(
                    title: collection.name,
                    collection: collection,
                    counters: filteredCounters(in: collection),
                    allCounters: allCounters,
                    isReorderingEnabled: isReorderingEnabled,
                    counterRowStride: counterRowStride,
                    folderSectionTopInset: folderSectionTopInset,
                    draggingCounter: $draggingCounter,
                    draggingCollection: $draggingCollection,
                    dragOverIndex: $dragOverIndex,
                    onEditCounter: onEditCounter,
                    onDeleteCounter: onDeleteCounter,
                    onEditCollection: onEditCollection,
                    onDeleteCollection: onDeleteCollection,
                    onBeginCounterDrag: { counter, index in
                        beginCounterDrag(counter, in: collection, at: index)
                    },
                    onEndDragSession: endDragSession
                )
            }
            if showsCollectionInsertionGap(before: filteredCollections.count) {
                ReorderInsertionGap(height: collectionHeaderStride)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: dragOverCollectionIndex)
        .modifier(CollectionSectionDropModifier(
            enabled: isReorderingEnabled,
            collectionCount: filteredCollections.count,
            rowStride: collectionHeaderStride,
            dragOverCollectionIndex: $dragOverCollectionIndex,
            shouldAcceptDrop: { draggingCollection != nil },
            onPerformDrop: { index in
                guard let draggingCollection else {
                    endDragSession(didCommit: false)
                    return
                }
                let adjusted = CounterReorder.adjustedCollectionIndex(
                    for: draggingCollection,
                    proposed: index,
                    collections: collections
                )
                CounterReorder.moveCollection(
                    draggingCollection,
                    to: adjusted,
                    collections: collections
                )
                endDragSession(didCommit: true)
            }
        ))
    }

    // MARK: - Drag handling

    private func beginCounterDrag(_ counter: Counter, in collection: CounterCollection?, at index: Int) {
        draggingCollection = nil
        draggingCounter = counter
        counterDragOrigin = CounterDragOrigin(collection: collection, index: index)
    }

    private func endDragSession(didCommit: Bool = false) {
        guard draggingCounter != nil || draggingCollection != nil || counterDragOrigin != nil else {
            return
        }

        if !didCommit, let draggingCounter, let origin = counterDragOrigin {
            CounterReorder.moveCounter(
                draggingCounter,
                to: origin.collection,
                at: origin.index,
                allCounters: allCounters
            )
        }

        draggingCounter = nil
        draggingCollection = nil
        dragOverIndex = nil
        dragOverCollectionIndex = nil
        counterDragOrigin = nil
    }

    private func showsCollectionInsertionGap(before index: Int) -> Bool {
        draggingCollection != nil && dragOverCollectionIndex == index
    }

    // MARK: - Filtering

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var isReorderingEnabled: Bool {
        trimmedSearchText.isEmpty
    }

    private var unassignedCounters: [Counter] {
        allCounters
            .filter { $0.collection == nil && matchesSearch($0) }
            .sorted(by: { $0.order < $1.order })
    }

    private var showsUnassignedSection: Bool {
        !unassignedCounters.isEmpty || draggingCounter != nil
    }

    private var filteredCollections: [CounterCollection] {
        if trimmedSearchText.isEmpty {
            return collections
        } else {
            return collections.filter { collection in
                collection.counters.contains(where: { matchesSearch($0) })
            }
        }
    }

    private func matchesSearch(_ counter: Counter) -> Bool {
        trimmedSearchText.isEmpty || counter.name.localizedCaseInsensitiveContains(trimmedSearchText)
    }

    private func filteredCounters(in collection: CounterCollection) -> [Counter] {
        collection.counters
            .filter { matchesSearch($0) }
            .sorted(by: { $0.order < $1.order })
    }
}
