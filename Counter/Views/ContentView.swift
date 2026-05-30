//
//  ContentView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData
import AVFoundation
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\CounterCollection.order)]) private var collections: [CounterCollection]
    @Query(sort: [SortDescriptor(\Counter.order)]) private var allCounters: [Counter]
    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var addCounterSheetDetent: PresentationDetent = .large
    @State private var editCounterSheetDetent: PresentationDetent = .large
    @State private var showNewCollectionSheet = false
    @State private var selectedCounter: Counter?
    @State private var dragOverSection: UUID? = nil
    @State private var dragOverIndex: CounterDropLocation? = nil
    @State private var draggingCounter: Counter? = nil

    private let counterRowStride: CGFloat = 64
    private let folderSectionTopInset: CGFloat = 10
    @State private var isUnassignedHeaderDropTarget: Bool = false
    @State private var counterToEdit: Counter? = nil
    @State private var showingDeleteConfirmation = false
    @State private var counterToDelete: Counter? = nil
    @State private var collectionToEdit: CounterCollection? = nil
    @State private var showingDeleteCollectionConfirmation = false
    @State private var collectionToDelete: CounterCollection? = nil

    var body: some View {
        NavigationStack {
            mainContent
                .searchable(text: $searchText, prompt: "Search counters")
                .navigationTitle("Counters")
                .toolbar { countersToolbar }
                .sheet(isPresented: $showAddSheet) { addCounterSheet }
                .onChange(of: showAddSheet) { _, isShowing in
                    if isShowing {
                        addCounterSheetDetent = .large
                    }
                }
                .sheet(isPresented: $showNewCollectionSheet) { newCollectionSheet }
                .sheet(item: $counterToEdit) { counter in editCounterSheet(for: counter) }
                .onChange(of: counterToEdit) { _, counter in
                    if counter != nil {
                        editCounterSheetDetent = .large
                    }
                }
                .sheet(item: $collectionToEdit) { collection in editCollectionSheet(for: collection) }
                .confirmationDialog("Delete Counter?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        if let counter = counterToDelete {
                            deleteCounter(counter)
                            counterToDelete = nil
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        counterToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this counter? This action cannot be undone.")
                }
                .confirmationDialog("Delete Collection?", isPresented: $showingDeleteCollectionConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        if let collection = collectionToDelete {
                            deleteCollection(collection)
                            collectionToDelete = nil
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        collectionToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this collection? All counters in this collection will be unassigned.")
                }
        }
        .task {
            // Pre-warm SwiftData by fetching a single Counter and CounterCollection
            do {
                let container = try? ModelContainer(for: Counter.self, CounterCollection.self)
                if let container {
                    let context = ModelContext(container)
                    var counterDescriptor = FetchDescriptor<Counter>()
                    counterDescriptor.fetchLimit = 1
                    _ = try? context.fetch(counterDescriptor)
                    var collectionDescriptor = FetchDescriptor<CounterCollection>()
                    collectionDescriptor.fetchLimit = 1
                    _ = try? context.fetch(collectionDescriptor)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if hasNoSearchResults {
            SearchNoResultsView(searchTerm: trimmedSearchText)
        } else {
            countersScrollView
        }
    }

    private var countersScrollView: some View {
        ScrollView {
            countersListStack
        }
    }

    private var countersListStack: some View {
        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
            if showsUnassignedSection {
                unassignedSection
            }
            ForEach(filteredCollections) { collection in
                collectionSection(for: collection)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsUnassignedSection)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .onDrop(of: ["public.text"], isTargeted: .constant(false), perform: { _ in
            endDragSession()
            return false
        })
    }

    private var unassignedSection: some View {
        folderSection(title: "Unassigned", collection: nil, counters: unassignedCounters)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func collectionSection(for collection: CounterCollection) -> some View {
        folderSection(
            title: collection.name,
            collection: collection,
            counters: filteredCounters(in: collection)
        )
    }

    @ToolbarContentBuilder
    private var countersToolbar: some ToolbarContent {
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            Menu {
                Button {
                    showAddSheet = true
                } label: {
                    Label("New Counter", systemImage: "plus.square")
                }
                Button {
                    showNewCollectionSheet = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private var addCounterSheet: some View {
        NavigationStack {
            AddCounterView(collections: collections)
                .environment(\.modelContext, context)
        }
        .presentationDetents([.medium, .large], selection: $addCounterSheetDetent)
    }

    private var newCollectionSheet: some View {
        NavigationStack {
            AddCollectionView(onAdd: { name in
                let newOrder = (collections.map { $0.order }.max() ?? 0) + 1
                let collection = CounterCollection(name: name, order: newOrder)
                context.insert(collection)
            })
        }
        .presentationDetents([.medium, .large])
    }

    private func editCounterSheet(for counter: Counter) -> some View {
        NavigationStack {
            EditCounterView(counter: counter, collections: collections)
                .environment(\.modelContext, context)
        }
        .presentationDetents([.medium, .large], selection: $editCounterSheetDetent)
    }

    private func editCollectionSheet(for collection: CounterCollection) -> some View {
        NavigationStack {
            EditCollectionView(collection: collection)
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Sections

    private var unassignedCounters: [Counter] {
        allCounters
            .filter { $0.collection == nil && matchesSearch($0) }
            .sorted(by: { $0.order < $1.order })
    }

    private var showsUnassignedSection: Bool {
        !unassignedCounters.isEmpty || draggingCounter != nil
    }

    private func endDragSession() {
        draggingCounter = nil
        dragOverIndex = nil
        dragOverSection = nil
        isUnassignedHeaderDropTarget = false
    }

    private func showsInsertionGap(in collectionID: UUID?, before index: Int) -> Bool {
        draggingCounter != nil
            && dragOverIndex?.collectionID == collectionID
            && dragOverIndex?.index == index
    }

    private func folderSection(title: String, collection: CounterCollection?, counters: [Counter]) -> some View {
        let collectionID = collection?.uuid
        return Section {
            folderSectionDivider
            VStack(spacing: 8) {
                ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                    if showsInsertionGap(in: collectionID, before: idx) {
                        reorderInsertionGap
                    }
                    DraggableCounterRow(
                        counter: counter,
                        isDragging: draggingCounter?.uuid == counter.uuid,
                        onDrag: {
                            draggingCounter = counter
                        },
                        onEdit: { counterToEdit = counter },
                        onDelete: { counterToDelete = counter; showingDeleteConfirmation = true }
                    )
                }
                if showsInsertionGap(in: collectionID, before: counters.count) {
                    reorderInsertionGap
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: dragOverIndex)
            .onDrop(
                of: ["public.text"],
                delegate: CounterSectionDropDelegate(
                    collectionID: collectionID,
                    counterCount: counters.count,
                    rowStride: counterRowStride,
                    topInset: folderSectionTopInset,
                    dragOverIndex: $dragOverIndex,
                    onPerformDrop: { index in
                        guard let draggingCounter else {
                            endDragSession()
                            return
                        }
                        let adjusted = adjustedInsertionIndex(
                            for: draggingCounter,
                            in: collection,
                            proposed: index,
                            destinationCounters: counters
                        )
                        moveCounter(draggingCounter, to: collection, at: adjusted)
                        endDragSession()
                    }
                )
            )
        } header: {
            folderPinnedTitle(title: title, collection: collection, counters: counters)
        }
    }

    private var folderSectionDivider: some View {
        Divider()
            .padding(.bottom, 6)
    }

    private var reorderInsertionGap: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.5))
            .frame(height: 3)
            .padding(.vertical, 2)
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .center)))
    }
    
    // MARK: - Filtering

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var hasNoSearchResults: Bool {
        !trimmedSearchText.isEmpty && !allCounters.contains(where: matchesSearch)
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
    
    // MARK: - Drop Logic

    private func handleDrop(to collection: CounterCollection?, at index: Int, providers: [NSItemProvider]) {
        if let draggingCounter {
            moveCounter(draggingCounter, to: collection, at: index)
            endDragSession()
            return
        }
        guard let provider = providers.first else {
            endDragSession()
            return
        }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, _ in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString,
                  let counter = DragDropUtils.fetchCounter(from: idString, context: context) else {
                DispatchQueue.main.async { endDragSession() }
                return
            }
            DispatchQueue.main.async {
                moveCounter(counter, to: collection, at: index)
                endDragSession()
            }
        }
    }

    private func adjustedInsertionIndex(
        for counter: Counter,
        in collection: CounterCollection?,
        proposed index: Int,
        destinationCounters: [Counter]
    ) -> Int {
        guard counter.collection === collection,
              let fromIndex = destinationCounters.firstIndex(where: { $0.uuid == counter.uuid }),
              fromIndex < index else {
            return index
        }
        return max(0, index - 1)
    }

    private func moveCounter(_ counter: Counter, to collection: CounterCollection?, at index: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            if let oldCollection = counter.collection {
                oldCollection.counters.removeAll { $0 === counter }
                let oldCounters = oldCollection.counters.sorted(by: { $0.order < $1.order })
                for (idx, c) in oldCounters.enumerated() { c.order = idx }
                oldCollection.counters = oldCounters
            } else {
                let unassigned = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
                let filtered = unassigned.filter { $0 !== counter }
                for (idx, c) in filtered.enumerated() { c.order = idx }
            }

            counter.collection = collection
            if let collection {
                var counters = collection.counters.sorted(by: { $0.order < $1.order })
                counters.removeAll { $0 === counter }
                let safeIndex = min(max(index, 0), counters.count)
                counters.insert(counter, at: safeIndex)
                for (idx, c) in counters.enumerated() { c.order = idx }
                collection.counters = counters
            } else {
                var unassigned = allCounters.filter { $0.collection == nil && $0 !== counter }.sorted(by: { $0.order < $1.order })
                let safeIndex = min(max(index, 0), unassigned.count)
                unassigned.insert(counter, at: safeIndex)
                for (idx, c) in unassigned.enumerated() {
                    c.order = idx
                    c.collection = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private func folderPinnedTitle(title: String, collection: CounterCollection?, counters: [Counter]) -> some View {
        let collectionID = collection?.uuid
        let titleLabel = folderTitleLabel(
            title: title,
            isTargeted: collectionID == nil
                ? $isUnassignedHeaderDropTarget
                : Binding(
                    get: { dragOverSection == collectionID },
                    set: { isTargeted in dragOverSection = isTargeted ? collectionID : nil }
                ),
            onDrop: { providers in
                handleDrop(to: collection, at: counters.count, providers: providers)
                return true
            }
        )
        if let collection {
            titleLabel.contextMenu {
                Button {
                    collectionToEdit = collection
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    collectionToDelete = collection
                    showingDeleteCollectionConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } else {
            titleLabel
        }
    }

    @ViewBuilder
    private func folderTitleLabel(
        title: String,
        isTargeted: Binding<Bool>? = nil,
        onDrop: (([NSItemProvider]) -> Bool)? = nil
    ) -> some View {
        let label = Text(title)
            .font(.subheadline)
            .fontWeight(.regular)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        if let onDrop, let isTargeted {
            label
                .onDrop(of: ["public.text"], isTargeted: isTargeted, perform: { providers in
                    onDrop(providers)
                })
                .onChange(of: isTargeted.wrappedValue) { _, newValue in
                    #if os(iOS)
                    if newValue {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    #endif
                }
        } else {
            label
        }
    }

    private func deleteCounter(_ counter: Counter) {
        context.delete(counter)
    }

    private func deleteCollection(_ collection: CounterCollection) {
        // Unassign all counters in this collection
        for counter in collection.counters {
            counter.collection = nil
        }
        context.delete(collection)
    }
}

// MARK: - CounterRowView
private struct CounterRowView: View {
    @Bindable var counter: Counter
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var isActive = false
    
    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(theme.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: counter.iconName ?? "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(counter.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("\(counter.value)")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    if let goal = counter.goalValue {
                        Text("/ \(goal)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isActive = true
            }

            Stepper(
                value: $counter.value,
                in: 0...9999,
                step: max(counter.step, 1)
            ) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: counter.value) { _, _ in
                counter.lastUpdated = Date()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: counter.value)
        .background(
            NavigationLink(destination: CounterView(counter: counter), isActive: $isActive) {
                EmptyView()
            }
            .opacity(0)
        )
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Divider()

            Button {
                #if os(iOS)
                UIPasteboard.general.string = "\(counter.value)"
                #endif
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }

            ShareLink(item: "\(counter.value)", subject: Text(counter.name)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    do {
        let container = try ModelContainer(
            for: Counter.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return NavigationStack {
            ContentView()
                .modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

// MARK: - Draggable row

// Helper view for a draggable counter row (drop handled per section)
private struct DraggableCounterRow: View {
    let counter: Counter
    let isDragging: Bool
    let onDrag: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        CounterRowView(counter: counter, onEdit: onEdit, onDelete: onDelete)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
            .opacity(isDragging ? 0.35 : 1)
            .scaleEffect(isDragging ? 0.97 : 1, anchor: .center)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDragging)
            .onDrag {
                onDrag()
                return DragDropUtils.createItemProvider(for: counter)
            } preview: {
                CounterDragPreview(counter: counter)
            }
    }
}

private struct CounterDragPreview: View {
    let counter: Counter

    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.gradient)
                    .frame(width: 40, height: 40)
                Image(systemName: counter.iconName ?? "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(counter.name)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
}

