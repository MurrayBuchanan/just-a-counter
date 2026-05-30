//
//  CounterReorder.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftData
import SwiftUI

struct CounterDragOrigin {
    let collection: CounterCollection?
    let index: Int
}

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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            if let oldCollection = counter.collection {
                oldCollection.counters.removeAll { $0 === counter }
                let oldCounters = oldCollection.counters.sorted(by: { $0.order < $1.order })
                for (idx, c) in oldCounters.enumerated() { c.order = idx }
                oldCollection.counters = oldCounters
            } else {
                let unassigned = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
                let filtered = unassigned.filter { $0 !== counter }
                for (idx, c) in filtered.enumerated() { c.order = idx }
            }

            counter.collection = collection
            if let collection {
                var counters = collection.counters.sorted(by: { $0.order < $1.order })
                counters.removeAll { $0 === counter }
                let safeIndex = min(max(index, 0), counters.count)
                counters.insert(counter, at: safeIndex)
                for (idx, c) in counters.enumerated() { c.order = idx }
                collection.counters = counters
            } else {
                var unassigned = allCounters.filter { $0.collection == nil && $0 !== counter }.sorted(by: { $0.order < $1.order })
                let safeIndex = min(max(index, 0), unassigned.count)
                unassigned.insert(counter, at: safeIndex)
                for (idx, c) in unassigned.enumerated() {
                    c.order = idx
                    c.collection = nil
                }
            }
        }
    }

    @MainActor
    static func moveCollection(
        _ collection: CounterCollection,
        to index: Int,
        collections: [CounterCollection]
    ) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            var ordered = collections.sorted(by: { $0.order < $1.order })
            ordered.removeAll { $0 === collection }
            let safeIndex = min(max(index, 0), ordered.count)
            ordered.insert(collection, at: safeIndex)
            for (idx, col) in ordered.enumerated() {
                col.order = idx
            }
        }
    }
}
