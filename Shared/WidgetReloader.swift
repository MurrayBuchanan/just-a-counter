//
//  WidgetReloader.swift
//  Counter
//

import Foundation
import WidgetKit

enum WidgetReloader {
    private static let debounceNanoseconds: UInt64 = 350_000_000
    private static var debouncedReloadTask: Task<Void, Never>?

    static func sync(_ counter: Counter) {
        CounterWidgetData.syncSnapshot(for: counter)
    }

    static func removeCounter(id: UUID) {
        WidgetSnapshotStore.remove(id: id)
        reloadCounterWidget()
    }

    /// Debounces rapid in-app value changes (e.g. stepper) so the widget is not hammered with reloads.
    static func scheduleReload(for counter: Counter) {
        sync(counter)
        debouncedReloadTask?.cancel()
        debouncedReloadTask = Task {
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }
            reloadCounterWidget()
        }
    }

    static func reloadCounterWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CounterWidgetKind.kind)
    }

    static func reloadAll() {
        reloadCounterWidget()
    }
}
