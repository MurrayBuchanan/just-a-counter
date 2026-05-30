//
//  SharedModelContainer.swift
//  Counter
//

import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.com.murrayb.Counter"

    static let shared: ModelContainer = {
        let schema = Schema([Counter.self, CounterCollection.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared model container: \(error)")
        }
    }()
}
