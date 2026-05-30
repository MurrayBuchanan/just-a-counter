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

// Minimal working drop delegate for diagnostic purposes
@MainActor
class MyDropDelegate: DropDelegate {
    let id: Int
    init(id: Int) { self.id = id }
    func performDrop(info: DropInfo) -> Bool { true }
}

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
    @State private var dragOverIndex: (collection: UUID?, index: Int)? = nil
    @State private var draggingCounterID: UUID? = nil
    @State private var isUnassignedHeaderDropTarget: Bool = false
    @State private var counterToEdit: Counter? = nil
    @State private var showingDeleteConfirmation = false
    @State private var counterToDelete: Counter? = nil
    @State private var collectionToEdit: CounterCollection? = nil
    @State private var showingDeleteCollectionConfirmation = false
    @State private var collectionToDelete: CounterCollection? = nil

    var body: some View {
        NavigationStack {
            Group {
                if hasNoSearchResults {
                    SearchNoResultsView(searchTerm: trimmedSearchText)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if showsUnassignedSection {
                                folderSection(title: "Unassigned", collection: nil, counters: unassignedCounters)
                            }
                            ForEach(filteredCollections) { collection in
                                folderSection(
                                    title: collection.name,
                                    collection: collection,
                                    counters: collection.counters
                                        .filter { matchesSearch($0) }
                                        .sorted(by: { $0.order < $1.order })
                                )
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search counters")
            .navigationTitle("Counters")
            .toolbar {
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
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    AddCounterView(collections: collections)
                        .environment(\.modelContext, context)
                }
                .presentationDetents([.medium, .large], selection: $addCounterSheetDetent)
            }
            .onChange(of: showAddSheet) { _, isShowing in
                if isShowing {
                    addCounterSheetDetent = .large
                }
            }
            .sheet(isPresented: $showNewCollectionSheet) {
                NavigationStack {
                    AddCollectionView(onAdd: { name in
                        let newOrder = (collections.map { $0.order }.max() ?? 0) + 1
                        let collection = CounterCollection(name: name, order: newOrder)
                        context.insert(collection)
                    })
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $counterToEdit) { counter in
                NavigationStack {
                    EditCounterView(counter: counter, collections: collections)
                        .environment(\.modelContext, context)
                }
                .presentationDetents([.medium, .large], selection: $editCounterSheetDetent)
            }
            .onChange(of: counterToEdit) { _, counter in
                if counter != nil {
                    editCounterSheetDetent = .large
                }
            }
            .sheet(item: $collectionToEdit) { collection in
                NavigationStack {
                    EditCollectionView(collection: collection)
                }
                .presentationDetents([.medium, .large])
            }
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
    
    // MARK: - Sections

    private var unassignedCounters: [Counter] {
        allCounters
            .filter { $0.collection == nil && matchesSearch($0) }
            .sorted(by: { $0.order < $1.order })
    }

    private var showsUnassignedSection: Bool {
        trimmedSearchText.isEmpty || !unassignedCounters.isEmpty
    }

    private func folderSection(title: String, collection: CounterCollection?, counters: [Counter]) -> some View {
        let collectionID = collection?.uuid
        return VStack(alignment: .leading, spacing: 0) {
            folderHeader(title: title, collection: collection, counters: counters)
            DropIndicator(isActive: dragOverIndex?.collection == collectionID && dragOverIndex?.index == 0)
                .onDrop(of: ["public.text"], isTargeted: Binding(
                    get: { dragOverIndex?.collection == collectionID && dragOverIndex?.index == 0 },
                    set: { isTargeted in dragOverIndex = isTargeted ? (collectionID, 0) : nil }
                ), perform: { providers in
                    handleDrop(to: collection, at: 0, providers: providers)
                    return true
                })
            ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                DraggableCounterRow(
                    counter: counter,
                    collectionID: collectionID,
                    idx: idx,
                    isDropTarget: dragOverIndex?.collection == collectionID && dragOverIndex?.index == idx,
                    onDrag: { draggingCounterID = counter.uuid },
                    onDrop: { providers in
                        handleDrop(to: collection, at: idx, providers: providers)
                        return true
                    },
                    dragOverIndex: $dragOverIndex,
                    onEdit: { counterToEdit = counter },
                    onDelete: { counterToDelete = counter; showingDeleteConfirmation = true }
                )
                .animation(.easeInOut, value: counter.order)
                DropIndicator(isActive: dragOverIndex?.collection == collectionID && dragOverIndex?.index == idx + 1)
                    .onDrop(of: ["public.text"], isTargeted: Binding(
                        get: { dragOverIndex?.collection == collectionID && dragOverIndex?.index == idx + 1 },
                        set: { isTargeted in dragOverIndex = isTargeted ? (collectionID, idx + 1) : nil }
                    ), perform: { providers in
                        handleDrop(to: collection, at: idx + 1, providers: providers)
                        return true
                    })
            }
        }
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
    
    // MARK: - Move and Drop Logic
    
    private func moveCountersInUnassigned(from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut) {
            var counters = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
            counters.move(fromOffsets: source, toOffset: destination)
            for (index, counter) in counters.enumerated() {
                counter.order = index
                counter.collection = nil
            }
        }
    }
    
    private func moveCountersInCollection(_ collection: CounterCollection, from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut) {
            var counters = collection.counters.sorted(by: { $0.order < $1.order })
            counters.move(fromOffsets: source, toOffset: destination)
            for (index, counter) in counters.enumerated() {
                counter.order = index
                counter.collection = collection
            }
            collection.counters = counters
        }
    }
    
    private func handleDrop(to collection: CounterCollection?, at index: Int, providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString,
                  let counter = DragDropUtils.fetchCounter(from: idString, context: context) else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    // Remove from old collection if needed
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
                    // Assign to new collection (or nil)
                    counter.collection = collection
                    if let collection = collection {
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
                        for (idx, c) in unassigned.enumerated() { c.order = idx; c.collection = nil }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func folderHeader(title: String, collection: CounterCollection?, counters: [Counter]) -> some View {
        let collectionID = collection?.uuid
        let header = sectionHeader(
            title: title,
            isDropTarget: collectionID == nil ? isUnassignedHeaderDropTarget : dragOverSection == collectionID,
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
            header.contextMenu {
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
            header
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, isDropTarget: Bool, isTargeted: Binding<Bool>? = nil, onDrop: (([NSItemProvider]) -> Bool)? = nil) -> some View {
        let header = VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)

            Divider()
        }
        .background(isDropTarget ? Color(UIColor.quaternaryLabel).opacity(0.35) : Color.clear)
        .contentShape(Rectangle())
        if let onDrop = onDrop, let isTargeted = isTargeted {
            header
                .onDrop(of: ["public.text"], isTargeted: isTargeted, perform: { providers in
                    let result = onDrop(providers)
                    return result
                })
                .onChange(of: isTargeted.wrappedValue) { newValue in
                    #if os(iOS)
                    if newValue {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    #endif
                }
        } else {
            header
        }
    }

    @ViewBuilder
    private func DropIndicator(isActive: Bool) -> some View {
        ZStack {
            // Invisible hit area for easier drop
            Color.clear
                .frame(height: 16)
            // Visible line
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? Color(UIColor.quaternaryLabel) : Color.clear)
                .frame(height: 4)
                .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .contentShape(Rectangle())
        .onChange(of: isActive) { newValue in
            #if os(iOS)
            if newValue {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            }
            #endif
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

struct CollectionEndDropDelegate: DropDelegate {
    let collection: CounterCollection
    let modelContext: ModelContext
    @Binding var draggedCounter: Counter?
    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = draggedCounter else { return false }
        if dragged.collection != collection {
            dragged.collection?.counters.removeAll { $0 === dragged }
            dragged.collection = collection
            collection.counters.append(dragged)
        }
        // Place at end
        let counters = collection.counters.sorted(by: { $0.order < $1.order })
        if let from = counters.firstIndex(where: { $0 === dragged }) {
            var mutable = counters
            mutable.move(fromOffsets: IndexSet(integer: from), toOffset: counters.count)
            for (index, counter) in mutable.enumerated() {
                counter.order = index
            }
        }
        draggedCounter = nil
        return true
    }
    func dropEntered(info: DropInfo) {}
    func dropExited(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
}

// MARK: - Drag & Drop Delegate (top-level, @MainActor)
@MainActor
class CounterDropDelegate: DropDelegate {
    let targetCounter: Counter
    let modelContext: ModelContext
    
    init(targetCounter: Counter, modelContext: ModelContext) {
        self.targetCounter = targetCounter
        self.modelContext = modelContext
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
            guard let data = data,
                  let id = String(data: data, encoding: .utf8),
                  let sourceCounter = DragDropUtils.fetchCounter(from: id, context: self.modelContext) else {
                return
            }
            // Update order of counters
            sourceCounter.order = self.targetCounter.order
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {}
    func dropExited(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
}

// Custom reorderable stack for counters
private struct CustomReorderableStack: View {
    let counters: [Counter]
    let collection: CounterCollection?
    @Binding var draggingCounter: Counter?
    @Binding var dragOverIndex: Int?
    let moveAction: (CounterCollection?, IndexSet, Int) -> Void
    
    var body: some View {
        // Use List with .onMove for smooth native reordering within a collection
        List {
        ForEach(Array(counters.enumerated()), id: \ .element.uuid) { idx, counter in
                CounterRowView(counter: counter)
                    
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemGroupedBackground).opacity(0.7))
                            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                    )
                    .scaleEffect(draggingCounter == counter ? 1.04 : 1.0)
                    .opacity(draggingCounter == counter ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: draggingCounter == counter)
                    .onDrag {
                        draggingCounter = counter
                        return NSItemProvider(object: counter.uuid.uuidString as NSString)
                    }
            }
            .onMove { indices, newOffset in
                moveAction(collection, indices, newOffset)
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: CGFloat(counters.count) * 54 + 10)
    }
}

// Helper view for a draggable and droppable counter row
private struct DraggableCounterRow: View {
    let counter: Counter
    let collectionID: UUID?
    let idx: Int
    let isDropTarget: Bool
    let onDrag: () -> Void
    let onDrop: ([NSItemProvider]) -> Bool
    @Binding var dragOverIndex: (collection: UUID?, index: Int)?
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            CounterRowView(counter: counter, onEdit: onEdit, onDelete: onDelete)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .animation(.easeInOut(duration: 0.25), value: counter.order)
                .onDrag {
                    onDrag()
                    return DragDropUtils.createItemProvider(for: counter)
                }
                .onDrop(of: ["public.text"], isTargeted: Binding(
                    get: { isDropTarget },
                    set: { isTargeted in
                        dragOverIndex = isTargeted ? (collectionID, idx) : nil
                    }
                ), perform: { providers in
                    let result = onDrop(providers)
                    dragOverIndex = nil
                    return result
                })
        }
    }
}

// Custom drop target view
private struct DropTargetView: View {
    let collection: CounterCollection?
    @Binding var isTargeted: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color(UIColor.quaternaryLabel) : Color.clear)
            .frame(height: 24)
            .cornerRadius(8)
            .onDrop(of: ["public.text"], isTargeted: $isTargeted, perform: onDrop)
            .padding(.vertical, 4)
    }
}

struct SectionDropDelegate: DropDelegate {
    let collection: CounterCollection?
    let allCounters: [Counter]
    let collections: [CounterCollection]
    let context: ModelContext
    let atIndex: Int
    let onDropComplete: () -> Void

    // Track if haptic has been triggered for this entry
    private var hasTriggeredHaptic = false
    private var lastDropTargetID: UUID? = nil

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString,
                  let counter = DragDropUtils.fetchCounter(from: idString, context: context) else { return }
            DispatchQueue.main.async {
                // Remove from old collection if needed
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
                // Assign to new collection (or nil)
                counter.collection = collection
                if let collection = collection {
                    var counters = collection.counters.sorted(by: { $0.order < $1.order })
                    counters.removeAll { $0 === counter }
                    counters.insert(counter, at: atIndex)
                    for (idx, c) in counters.enumerated() { c.order = idx }
                    collection.counters = counters
                } else {
                    var unassigned = allCounters.filter { $0.collection == nil && $0 !== counter }.sorted(by: { $0.order < $1.order })
                    unassigned.insert(counter, at: atIndex)
                    for (idx, c) in unassigned.enumerated() { c.order = idx; c.collection = nil }
                }
                onDropComplete()
            }
        }
        return true
    }

    func dropEntered(info: DropInfo) {
        // Haptic feedback when entering a collection drop target
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
    func dropExited(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
}

