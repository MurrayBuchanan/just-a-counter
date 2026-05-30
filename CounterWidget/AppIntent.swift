//
//  AppIntent.swift
//  CounterWidget
//

import AppIntents
import SwiftData
import WidgetKit

struct CounterEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Counter")
    static var defaultQuery = CounterQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CounterQuery: EntityQuery {
    func entities(for identifiers: [CounterEntity.ID]) async throws -> [CounterEntity] {
        guard !identifiers.isEmpty else { return [] }

        let cached = identifiers.compactMap { WidgetSnapshotStore.load(id: $0) }
        if cached.count == identifiers.count {
            return cached.map { CounterEntity(id: $0.id, name: $0.name) }
        }

        let context = ModelContext(SharedModelContainer.shared)
        let ids = identifiers
        var descriptor = FetchDescriptor<Counter>(
            predicate: #Predicate { ids.contains($0.uuid) }
        )
        let counters = try context.fetch(descriptor)
        return counters.map { CounterEntity(id: $0.uuid, name: $0.name) }
    }

    func suggestedEntities() async throws -> [CounterEntity] {
        let cached = WidgetSnapshotStore.sortedSnapshots()
        if !cached.isEmpty {
            return cached.map { CounterEntity(id: $0.id, name: $0.name) }
        }

        let context = ModelContext(SharedModelContainer.shared)
        let counters = try context.fetch(
            FetchDescriptor<Counter>(sortBy: [SortDescriptor(\.order)])
        )
        return counters.map { CounterEntity(id: $0.uuid, name: $0.name) }
    }
}

struct SelectCounterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Counter"
    static var description = IntentDescription("Choose which counter to display on your Home Screen.")

    @Parameter(title: "Counter")
    var counter: CounterEntity?
}

struct AdjustCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "Adjust Counter"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Counter")
    var counter: CounterEntity

    @Parameter(title: "Delta")
    var delta: Int

    init() {
        counter = CounterEntity(id: UUID(), name: "")
        delta = 0
    }

    init(counter: CounterEntity, delta: Int) {
        self.counter = counter
        self.delta = delta
    }

    func perform() async throws -> some IntentResult {
        try CounterWidgetData.adjustCounter(id: counter.id, by: delta)
        WidgetCenter.shared.reloadTimelines(ofKind: CounterWidgetKind.kind)
        return .result()
    }
}
