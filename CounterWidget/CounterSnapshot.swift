//
//  CounterSnapshot.swift
//  CounterWidget
//

import Foundation
import SwiftData

struct CounterSnapshot {
    let id: UUID
    let name: String
    let value: Int
    let goalValue: Int?
    let iconName: String?
    let themeName: String

    static let preview = CounterSnapshot(
        id: UUID(),
        name: "Push-ups",
        value: 42,
        goalValue: 100,
        iconName: "figure.strengthtraining.traditional",
        themeName: "blue"
    )
}

enum CounterWidgetData {
    static func loadCounter(id: UUID?) -> CounterSnapshot? {
        guard let id else { return nil }

        let context = ModelContext(SharedModelContainer.shared)
        let targetID = id
        var descriptor = FetchDescriptor<Counter>(
            predicate: #Predicate { $0.uuid == targetID }
        )
        descriptor.fetchLimit = 1

        guard let counter = try? context.fetch(descriptor).first else { return nil }

        return CounterSnapshot(
            id: counter.uuid,
            name: counter.name,
            value: counter.value,
            goalValue: counter.goalValue,
            iconName: counter.iconName,
            themeName: counter.themeName
        )
    }
}
