import Foundation
import SwiftData
import SwiftUI

@Model
final class CounterCollection: Identifiable, Hashable {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Counter.collection)
    var counters: [Counter] = []
    var order: Int = 0
    var iconName: String? = nil
    var uuid: UUID = UUID()
    
    init(name: String, order: Int = 0, iconName: String? = nil, uuid: UUID = UUID()) {
        self.name = name
        self.order = order
        self.iconName = iconName
        self.uuid = uuid
    }
    
    var id: UUID { uuid }
    
    static func == (lhs: CounterCollection, rhs: CounterCollection) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

@Model
final class Counter {
    var name: String
    var value: Int
    var dailyIncrement: Int
    var step: Int
    var createdAt: Date
    var iconName: String?
    var lastUpdated: Date
    var order: Int
    var uuid: UUID = UUID()
    
    // Goal-related properties
    var goalValue: Int?
    var goalDate: Date?
    var isCountingUp: Bool
    
    // Theme selection
    var themeName: String
    var layoutStyle: String = CounterLayoutStyle.standard.rawValue
    
    var collection: CounterCollection?
    
    var layout: CounterLayoutStyle {
        get { CounterLayoutStyle(rawValue: layoutStyle) ?? .standard }
        set { layoutStyle = newValue.rawValue }
    }
    
    init(
        name: String,
        value: Int = 0,
        dailyIncrement: Int = 0,
        step: Int = 1,
        createdAt: Date = Date(),
        iconName: String? = nil,
        notes: String? = nil,
        goalValue: Int? = nil,
        goalDate: Date? = nil,
        isCountingUp: Bool = true,
        order: Int = 0,
        themeName: String = "blue",
        layoutStyle: String = CounterLayoutStyle.standard.rawValue,
        collection: CounterCollection? = nil,
        uuid: UUID = UUID()
    ) {
        self.name = name
        self.value = value
        self.dailyIncrement = dailyIncrement
        self.step = step
        self.createdAt = createdAt
        self.iconName = iconName
        self.lastUpdated = createdAt
        self.goalValue = goalValue
        self.goalDate = goalDate
        self.isCountingUp = isCountingUp
        self.order = order
        self.themeName = themeName
        self.layoutStyle = layoutStyle
        self.collection = collection
        self.uuid = uuid
    }
    
    /// Whether the counter has met its goal.
    var hasReachedGoal: Bool {
        guard let goal = goalValue else { return false }
        return isCountingUp ? value >= goal : value <= 0
    }
}

extension Counter: Identifiable {
    var id: UUID { uuid }
}
