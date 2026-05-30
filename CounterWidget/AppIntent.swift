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
        let context = ModelContext(SharedModelContainer.shared)
        let counters = try context.fetch(FetchDescriptor<Counter>())
        return counters
            .filter { identifiers.contains($0.uuid) }
            .map { CounterEntity(id: $0.uuid, name: $0.name) }
    }

    func suggestedEntities() async throws -> [CounterEntity] {
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
