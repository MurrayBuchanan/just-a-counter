//
//  CounterWidgetData.swift
//  Counter
//

import Foundation
import SwiftData

enum CounterWidgetKind {
    static let kind = "CounterWidget"
}

enum CounterWidgetData {
    static func loadCounter(id: UUID?) -> CounterSnapshot? {
        guard let id else { return nil }

        if let cached = WidgetSnapshotStore.load(id: id) {
            return cached
        }

        guard let snapshot = fetchSnapshot(id: id) else { return nil }
        WidgetSnapshotStore.save(snapshot)
        return snapshot
    }

    @discardableResult
    static func adjustCounter(id: UUID, by delta: Int) throws -> CounterSnapshot? {
        let context = ModelContext(SharedModelContainer.shared)
        let targetID = id
        var descriptor = FetchDescriptor<Counter>(
            predicate: #Predicate { $0.uuid == targetID }
        )
        descriptor.fetchLimit = 1

        guard let counter = try context.fetch(descriptor).first else { return nil }
        guard !counter.isLocked else {
            return CounterSnapshot(counter: counter)
        }

        counter.value = CounterValueBounds.clamp(counter.value + delta)
        counter.lastUpdated = Date()
        try context.save()

        let snapshot = CounterSnapshot(counter: counter)
        WidgetSnapshotStore.save(snapshot)
        return snapshot
    }

    static func syncSnapshot(for counter: Counter) {
        WidgetSnapshotStore.save(CounterSnapshot(counter: counter))
    }

    static func warmCacheIfNeeded() {
        guard WidgetSnapshotStore.loadAll().isEmpty else { return }

        let context = ModelContext(SharedModelContainer.shared)
        guard let counters = try? context.fetch(FetchDescriptor<Counter>()) else { return }

        for counter in counters {
            WidgetSnapshotStore.save(CounterSnapshot(counter: counter))
        }
    }

    private static func fetchSnapshot(id: UUID) -> CounterSnapshot? {
        let context = ModelContext(SharedModelContainer.shared)
        let targetID = id
        var descriptor = FetchDescriptor<Counter>(
            predicate: #Predicate { $0.uuid == targetID }
        )
        descriptor.fetchLimit = 1

        guard let counter = try? context.fetch(descriptor).first else { return nil }
        return CounterSnapshot(counter: counter)
    }
}
