//
//  WidgetSnapshotStore.swift
//  Counter
//

import Foundation

/// Lightweight App Group cache so widget timelines read synchronously without opening SwiftData.
enum WidgetSnapshotStore {
    private static let snapshotsKey = "counterWidgetSnapshots"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedModelContainer.appGroupID)
    }

    static func save(_ snapshot: CounterSnapshot) {
        var snapshots = loadAll()
        snapshots[snapshot.id] = snapshot
        persist(snapshots)
    }

    static func remove(id: UUID) {
        var snapshots = loadAll()
        snapshots.removeValue(forKey: id)
        persist(snapshots)
    }

    static func load(id: UUID) -> CounterSnapshot? {
        loadAll()[id]
    }

    static func loadAll() -> [UUID: CounterSnapshot] {
        guard
            let data = defaults?.data(forKey: snapshotsKey),
            let decoded = try? JSONDecoder().decode([UUID: CounterSnapshot].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    static func sortedSnapshots() -> [CounterSnapshot] {
        loadAll().values.sorted { $0.order < $1.order }
    }

    private static func persist(_ snapshots: [UUID: CounterSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        defaults?.set(data, forKey: snapshotsKey)
    }
}
