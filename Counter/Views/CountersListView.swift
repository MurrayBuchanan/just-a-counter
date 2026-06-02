//
//  CountersListView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct CountersListView: View {
    static let unassignedFolderTitle = "Unassigned"

    let collections: [CounterCollection]
    let allCounters: [Counter]
    let searchText: String

    var onEditCounter: (Counter) -> Void
    var onMoveCounter: (Counter, CounterCollection?) -> Void
    var onDuplicateCounter: (Counter) -> Void
    var onDeleteCounter: (Counter) -> Void
    var onEditCollection: (CounterCollection) -> Void
    var onDeleteCollection: (CounterCollection) -> Void

    @State private var dragOverIndex: CounterDropLocation? = nil
    @State private var dragOverCollectionIndex: Int? = nil
    @State private var draggingCounterID: UUID? = nil
    @State private var draggingCollection: CounterCollection? = nil
    @State private var isEndingDragSession = false
    @State private var dragCancelTask: Task<Void, Never>?
    /// True only after the drag has entered its first drop target — used to gate layout changes
    /// so a context-menu long-press never triggers compact mode.
    @State private var isDragLayoutActive = false

    private let counterRowStride: CGFloat = CounterRowMetrics.rowStride
    private let collectionHeaderStride: CGFloat = 56

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                collectionSectionsStack
                if showsUnassignedSection {
                    unassignedSection
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .onDrop(of: [.text], isTargeted: .constant(false), perform: { _ in
            scheduleEndDragSession()
            return false
        })
        .onChange(of: draggingCounterID) { _, newID in
            if newID != nil { scheduleDragCancellation() }
        }
        .onChange(of: draggingCollection) { _, newCollection in
            if newCollection != nil { scheduleDragCancellation() }
        }
        .onChange(of: dragOverIndex) { _, new in
            if new != nil {
                dragCancelTask?.cancel()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isDragLayoutActive = true
                }
            } else if draggingCounterID != nil || draggingCollection != nil {
                scheduleDragCancellation()
            }
        }
        .onChange(of: dragOverCollectionIndex) { _, new in
            if new != nil {
                dragCancelTask?.cancel()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isDragLayoutActive = true
                }
            } else if draggingCounterID != nil || draggingCollection != nil {
                scheduleDragCancellation()
            }
        }
    }

    // MARK: - Sections

    private var unassignedSection: some View {
        CounterFolderSectionView(
            title: Self.unassignedFolderTitle,
            collection: nil,
            counters: unassignedCounters,
            allCounters: allCounters,
            collections: collections,
            isReorderingEnabled: isReorderingEnabled,
            counterRowStride: counterRowStride,
            isDragLayoutActive: isDragLayoutActive,
            draggingCounterID: $draggingCounterID,
            draggingCollection: $draggingCollection,
            dragOverIndex: $dragOverIndex,
            onEditCounter: onEditCounter,
            onMoveCounter: onMoveCounter,
            onDuplicateCounter: onDuplicateCounter,
            onDeleteCounter: onDeleteCounter,
            onBeginCounterDrag: { counter, index in
                beginCounterDrag(counter, at: index)
            },
            onEndDragSession: endDragSession
        )
    }

    /// Omits the dragged folder from layout once it has entered a drop target.
    /// Keeping it visible until then prevents it disappearing during a context menu long-press.
    private var listCollections: [CounterCollection] {
        guard let draggingCollection, dragOverCollectionIndex != nil else { return filteredCollections }
        return filteredCollections.filter { $0.uuid != draggingCollection.uuid }
    }

    private var dropTargetCollectionCount: Int {
        draggingCollection == nil ? filteredCollections.count : listCollections.count
    }

    private var collectionSectionsStack: some View {
        VStack(spacing: 16) {
            ForEach(Array(listCollections.enumerated()), id: \.element.uuid) { idx, collection in
                if showsCollectionInsertionGap(before: idx) {
                    ReorderInsertionGap(height: collectionHeaderStride)
                }
                CounterFolderSectionView(
                    title: collection.name,
                    collection: collection,
                    counters: filteredCounters(in: collection),
                    allCounters: allCounters,
                    collections: collections,
                    isReorderingEnabled: isReorderingEnabled,
                    counterRowStride: counterRowStride,
                    isDragLayoutActive: isDragLayoutActive,
                    draggingCounterID: $draggingCounterID,
                    draggingCollection: $draggingCollection,
                    dragOverIndex: $dragOverIndex,
                    onEditCounter: onEditCounter,
                    onMoveCounter: onMoveCounter,
                    onDuplicateCounter: onDuplicateCounter,
                    onDeleteCounter: onDeleteCounter,
                    onEditCollection: onEditCollection,
                    onDeleteCollection: onDeleteCollection,
                    onBeginCounterDrag: { counter, index in
                        beginCounterDrag(counter, at: index)
                    },
                    onEndDragSession: endDragSession
                )
            }
            if showsCollectionInsertionGap(before: listCollections.count) {
                ReorderInsertionGap(height: collectionHeaderStride)
            }
        }
        .modifier(CollectionSectionDropModifier(
            enabled: isReorderingEnabled,
            collectionCount: dropTargetCollectionCount,
            rowStride: collectionHeaderStride,
            dragOverCollectionIndex: $dragOverCollectionIndex,
            shouldAcceptDrop: { draggingCollection != nil },
            onPerformDrop: { index in
                guard let draggingCollection else {
                    scheduleEndDragSession()
                    return
                }
                let adjusted = CounterReorder.adjustedCollectionIndex(
                    for: draggingCollection,
                    proposed: index,
                    collections: collections
                )
                scheduleEndDragSession()
                DispatchQueue.main.async {
                    CounterReorder.moveCollection(
                        draggingCollection,
                        to: adjusted,
                        collections: collections
                    )
                }
            }
        ))
    }

    // MARK: - Drag handling

    private func beginCounterDrag(_ counter: Counter, at _: Int) {
        draggingCollection = nil
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            draggingCounterID = counter.uuid
        }
    }

    private func scheduleEndDragSession() {
        DispatchQueue.main.async {
            endDragSession()
        }
    }

    /// Resets drag UI state only. SwiftData is unchanged until a valid drop commits via `moveCounter`.
    private func endDragSession() {
        dragCancelTask?.cancel()
        dragCancelTask = nil
        guard !isEndingDragSession else { return }
        guard draggingCounterID != nil || draggingCollection != nil else { return }
        isEndingDragSession = true

        draggingCounterID = nil
        draggingCollection = nil
        dragOverIndex = nil
        dragOverCollectionIndex = nil
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isDragLayoutActive = false
        }
        isEndingDragSession = false
    }

    /// Cancels the drag state if no drop target has been entered within 500ms.
    /// This handles the case where onDrag fires during a context menu long-press
    /// but no real drag movement occurs.
    private func scheduleDragCancellation() {
        dragCancelTask?.cancel()
        dragCancelTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                return
            }
            guard dragOverIndex == nil, dragOverCollectionIndex == nil else { return }
            endDragSession()
        }
    }

    private func showsCollectionInsertionGap(before index: Int) -> Bool {
        guard let dragOverCollectionIndex, draggingCollection != nil else { return false }
        return dragOverCollectionIndex == index
    }

    // MARK: - Filtering

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var isReorderingEnabled: Bool {
        trimmedSearchText.isEmpty
    }

    private var unassignedFolderMatchesSearch: Bool {
        !trimmedSearchText.isEmpty
            && Self.unassignedFolderTitle.localizedCaseInsensitiveContains(trimmedSearchText)
    }

    private var unassignedCounters: [Counter] {
        let unassigned = allCounters.filter { $0.collection == nil }
        let counters: [Counter]
        if trimmedSearchText.isEmpty || unassignedFolderMatchesSearch {
            counters = unassigned
        } else {
            counters = unassigned.filter { counterMatchesSearch($0) }
        }
        return counters.sorted(by: { $0.order < $1.order })
    }

    private var showsUnassignedSection: Bool {
        if trimmedSearchText.isEmpty {
            return !unassignedCounters.isEmpty || isDragLayoutActive
        }
        if unassignedFolderMatchesSearch { return true }
        return !unassignedCounters.isEmpty
    }

    private var filteredCollections: [CounterCollection] {
        if trimmedSearchText.isEmpty {
            return collections
        } else {
            return collections.filter { collection in
                collectionMatchesSearch(collection)
                    || collection.counters.contains(where: { counterMatchesSearch($0) })
            }
        }
    }

    private func collectionMatchesSearch(_ collection: CounterCollection) -> Bool {
        trimmedSearchText.isEmpty
            || collection.name.localizedCaseInsensitiveContains(trimmedSearchText)
    }

    private func counterMatchesSearch(_ counter: Counter) -> Bool {
        trimmedSearchText.isEmpty || counter.name.localizedCaseInsensitiveContains(trimmedSearchText)
    }

    private func filteredCounters(in collection: CounterCollection) -> [Counter] {
        let counters = collectionMatchesSearch(collection)
            ? collection.counters
            : collection.counters.filter { counterMatchesSearch($0) }
        return counters.sorted(by: { $0.order < $1.order })
    }
}
