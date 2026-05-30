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

    @State private var dragOverSection: UUID? = nil
    @State private var dragOverIndex: CounterDropLocation? = nil
    @State private var dragOverCollectionIndex: Int? = nil
    @State private var draggingCounter: Counter? = nil
    @State private var draggingCollection: CounterCollection? = nil
    @State private var isUnassignedHeaderDropTarget = false

    private let counterRowStride: CGFloat = 64
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
            .onDrop(of: [.text], isTargeted: .constant(false), perform: { _ in
                endDragSession()
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
            dragOverSection: $dragOverSection,
            isUnassignedHeaderDropTarget: $isUnassignedHeaderDropTarget,
            onEditCounter: onEditCounter,
            onDeleteCounter: onDeleteCounter,
            onCounterDrop: handleCounterDrop,
            onEndDragSession: endDragSession
        )
    }

    private var collectionSectionsStack: some View {
        VStack(spacing: 16) {
            ForEach(Array(filteredCollections.enumerated()), id: \.element.uuid) { idx, collection in
                if showsCollectionInsertionGap(before: idx) {
                    ReorderInsertionGap()
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
                    dragOverSection: $dragOverSection,
                    isUnassignedHeaderDropTarget: $isUnassignedHeaderDropTarget,
                    onEditCounter: onEditCounter,
                    onDeleteCounter: onDeleteCounter,
                    onEditCollection: onEditCollection,
                    onDeleteCollection: onDeleteCollection,
                    onCounterDrop: handleCounterDrop,
                    onEndDragSession: endDragSession
                )
            }
            if showsCollectionInsertionGap(before: filteredCollections.count) {
                ReorderInsertionGap()
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
                    endDragSession()
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
                endDragSession()
            }
        ))
    }

    // MARK: - Drag handling

    private func endDragSession() {
        draggingCounter = nil
        draggingCollection = nil
        dragOverIndex = nil
        dragOverSection = nil
        dragOverCollectionIndex = nil
        isUnassignedHeaderDropTarget = false
    }

    private func showsCollectionInsertionGap(before index: Int) -> Bool {
        draggingCollection != nil && dragOverCollectionIndex == index
    }

    private func handleCounterDrop(to collection: CounterCollection?, at index: Int, providers: [NSItemProvider]) {
        if let draggingCounter {
            CounterReorder.moveCounter(
                draggingCounter,
                to: collection,
                at: index,
                allCounters: allCounters
            )
            endDragSession()
            return
        }
        guard let provider = providers.first else {
            endDragSession()
            return
        }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, _ in
            let idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            } else {
                idString = nil
            }
            guard let idString, let uuid = UUID(uuidString: idString) else {
                DispatchQueue.main.async { endDragSession() }
                return
            }
            DispatchQueue.main.async {
                guard let counter = allCounters.first(where: { $0.uuid == uuid }) else {
                    endDragSession()
                    return
                }
                draggingCollection = nil
                draggingCounter = counter
                CounterReorder.moveCounter(
                    counter,
                    to: collection,
                    at: index,
                    allCounters: allCounters
                )
                endDragSession()
            }
        }
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
