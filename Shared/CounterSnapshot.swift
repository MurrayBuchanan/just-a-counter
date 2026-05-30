//
//  CounterSnapshot.swift
//  Counter
//

import Foundation

struct CounterSnapshot: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let value: Int
    let step: Int
    let goalValue: Int?
    let iconName: String?
    let themeName: String
    let order: Int

    init(
        id: UUID,
        name: String,
        value: Int,
        step: Int,
        goalValue: Int?,
        iconName: String?,
        themeName: String,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.step = step
        self.goalValue = goalValue
        self.iconName = iconName
        self.themeName = themeName
        self.order = order
    }

    init(counter: Counter) {
        id = counter.uuid
        name = counter.name
        value = counter.value
        step = counter.step
        goalValue = counter.goalValue
        iconName = counter.iconName
        themeName = counter.themeName
        order = counter.order
    }

    static let preview = CounterSnapshot(
        id: UUID(),
        name: "Push-ups",
        value: 42,
        step: 1,
        goalValue: 100,
        iconName: "figure.strengthtraining.traditional",
        themeName: "blue"
    )
}
