//
//  ContentView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\CounterCollection.order)]) private var collections: [CounterCollection]
    @Query(sort: [SortDescriptor(\Counter.order)]) private var allCounters: [Counter]

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showAddSheet = false
    @State private var addCounterSheetDetent: PresentationDetent = .large
    @State private var editCounterSheetDetent: PresentationDetent = .large
    @State private var showNewCollectionSheet = false
    @State private var counterToEdit: Counter? = nil
    @State private var showingDeleteConfirmation = false
    @State private var counterToDelete: Counter? = nil
    @State private var collectionToEdit: CounterCollection? = nil
    @State private var showingDeleteCollectionConfirmation = false
    @State private var collectionToDelete: CounterCollection? = nil

    var body: some View {
        NavigationStack {
            mainContent
                .task { CounterWidgetData.warmCacheIfNeeded() }
                .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search")
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
            CountersListView(
                collections: collections,
                allCounters: allCounters,
                searchText: searchText,
                onEditCounter: { counterToEdit = $0 },
                onDeleteCounter: { counter in
                    counterToDelete = counter
                    showingDeleteConfirmation = true
                },
                onEditCollection: { collectionToEdit = $0 },
                onDeleteCollection: { collection in
                    collectionToDelete = collection
                    showingDeleteCollectionConfirmation = true
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var countersToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button { isSearchPresented = true } label: {
                Image(systemName: "magnifyingglass")
            }
        }
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

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var hasNoSearchResults: Bool {
        guard !trimmedSearchText.isEmpty else { return false }
        let counterMatch = allCounters.contains { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
        let folderMatch = collections.contains { $0.name.localizedCaseInsensitiveContains(trimmedSearchText) }
        let hasUnassigned = allCounters.contains { $0.collection == nil }
        let unassignedFolderMatch = hasUnassigned && CountersListView.unassignedFolderTitle
            .localizedCaseInsensitiveContains(trimmedSearchText)
        return !counterMatch && !folderMatch && !unassignedFolderMatch
    }

    private func deleteCounter(_ counter: Counter) {
        let id = counter.uuid
        context.delete(counter)
        WidgetReloader.removeCounter(id: id)
    }

    private func deleteCollection(_ collection: CounterCollection) {
        for counter in collection.counters {
            counter.collection = nil
        }
        context.delete(collection)
    }
}

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
