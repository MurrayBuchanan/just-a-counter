//
//  CounterReorder.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftData

enum CounterReorder {
    static func adjustedInsertionIndex(
        for counter: Counter,
        in collection: CounterCollection?,
        proposed index: Int,
        destinationCounters: [Counter]
    ) -> Int {
        guard counter.collection === collection,
              let fromIndex = destinationCounters.firstIndex(where: { $0.uuid == counter.uuid }),
              fromIndex < index else {
            return index
        }
        return max(0, index - 1)
    }

    static func adjustedCollectionIndex(
        for collection: CounterCollection,
        proposed index: Int,
        collections: [CounterCollection]
    ) -> Int {
        guard let fromIndex = collections.firstIndex(where: { $0.uuid == collection.uuid }),
              fromIndex < index else {
            return index
        }
        return max(0, index - 1)
    }

    @MainActor
    static func moveCounter(
        _ counter: Counter,
        to collection: CounterCollection?,
        at index: Int,
        allCounters: [Counter]
    ) {
        let sourceCollection = counter.collection

        if sourceCollection !== collection {
            if let sourceCollection {
                sourceCollection.counters.removeAll { $0 === counter }
                normalizeOrders(in: sourceCollection)
            } else {
                normalizeUnassignedOrders(allCounters: allCounters, excluding: counter)
            }
            counter.collection = collection
        }

        if let collection {
            var ordered = collection.counters
                .filter { $0 !== counter }
                .sorted(by: { $0.order < $1.order })
            let safeIndex = min(max(index, 0), ordered.count)
            ordered.insert(counter, at: safeIndex)
            normalizeOrders(for: ordered)
            collection.counters = ordered
            counter.collection = collection
        } else {
            var unassigned = allCounters
                .filter { $0.collection == nil && $0 !== counter }
                .sorted(by: { $0.order < $1.order })
            let safeIndex = min(max(index, 0), unassigned.count)
            unassigned.insert(counter, at: safeIndex)
            for (idx, c) in unassigned.enumerated() {
                c.order = idx
                c.collection = nil
            }
        }
    }

    @MainActor
    static func moveCollection(
        _ collection: CounterCollection,
        to index: Int,
        collections: [CounterCollection]
    ) {
        var ordered = collections.sorted(by: { $0.order < $1.order })
        ordered.removeAll { $0 === collection }
        let safeIndex = min(max(index, 0), ordered.count)
        ordered.insert(collection, at: safeIndex)
        for (idx, col) in ordered.enumerated() {
            col.order = idx
        }
    }

    private static func normalizeOrders(in collection: CounterCollection) {
        normalizeOrders(for: collection.counters.sorted(by: { $0.order < $1.order }))
        collection.counters = collection.counters.sorted(by: { $0.order < $1.order })
    }

    private static func normalizeOrders(for counters: [Counter]) {
        for (idx, counter) in counters.enumerated() {
            counter.order = idx
        }
    }

    private static func normalizeUnassignedOrders(allCounters: [Counter], excluding counter: Counter) {
        let unassigned = allCounters
            .filter { $0.collection == nil && $0 !== counter }
            .sorted(by: { $0.order < $1.order })
        for (idx, c) in unassigned.enumerated() {
            c.order = idx
        }
    }
}
