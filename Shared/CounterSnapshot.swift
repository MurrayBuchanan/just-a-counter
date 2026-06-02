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
    let isLocked: Bool

    init(
        id: UUID,
        name: String,
        value: Int,
        step: Int,
        goalValue: Int?,
        iconName: String?,
        themeName: String,
        order: Int = 0,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.step = step
        self.goalValue = goalValue
        self.iconName = iconName
        self.themeName = themeName
        self.order = order
        self.isLocked = isLocked
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
        isLocked = counter.isLocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Int.self, forKey: .value)
        step = try container.decode(Int.self, forKey: .step)
        goalValue = try container.decodeIfPresent(Int.self, forKey: .goalValue)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        themeName = try container.decode(String.self, forKey: .themeName)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, value, step, goalValue, iconName, themeName, order, isLocked
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
