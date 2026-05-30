//
//  CounterWidget.swift
//  CounterWidget
//

import WidgetKit
import SwiftUI

struct CounterEntry: TimelineEntry {
    let date: Date
    let counter: CounterSnapshot?
}

struct CounterWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CounterEntry {
        CounterEntry(date: .now, counter: .preview)
    }

    func snapshot(for configuration: SelectCounterIntent, in context: Context) async -> CounterEntry {
        entry(for: configuration, isPreview: context.isPreview)
    }

    func timeline(for configuration: SelectCounterIntent, in context: Context) async -> Timeline<CounterEntry> {
        let entry = entry(for: configuration, isPreview: false)
        // Counter data is pushed via App Intents and app-side reloads; avoid periodic SwiftData reads.
        return Timeline(entries: [entry], policy: .never)
    }

    private func entry(for configuration: SelectCounterIntent, isPreview: Bool) -> CounterEntry {
        let counter: CounterSnapshot?
        if isPreview {
            counter = .preview
        } else {
            counter = CounterWidgetData.loadCounter(id: configuration.counter?.id)
        }
        return CounterEntry(date: .now, counter: counter)
    }
}

struct CounterWidget: Widget {
    let kind = CounterWidgetKind.kind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCounterIntent.self,
            provider: CounterWidgetProvider()
        ) { entry in
            CounterWidgetView(entry: entry)
        }
        .configurationDisplayName("Counter")
        .description("Show a counter on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension SelectCounterIntent {
    fileprivate static var preview: SelectCounterIntent {
        let intent = SelectCounterIntent()
        intent.counter = CounterEntity(id: CounterSnapshot.preview.id, name: CounterSnapshot.preview.name)
        return intent
    }
}

#Preview(as: .systemSmall) {
    CounterWidget()
} timeline: {
    CounterEntry(date: .now, counter: .preview)
}

#Preview(as: .systemMedium) {
    CounterWidget()
} timeline: {
    CounterEntry(date: .now, counter: .preview)
}
