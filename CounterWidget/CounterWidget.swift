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
        CounterEntry(
            date: .now,
            counter: CounterWidgetData.loadCounter(id: configuration.counter?.id)
        )
    }

    func timeline(for configuration: SelectCounterIntent, in context: Context) async -> Timeline<CounterEntry> {
        let entry = CounterEntry(
            date: .now,
            counter: CounterWidgetData.loadCounter(id: configuration.counter?.id)
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct CounterWidget: Widget {
    let kind = "CounterWidget"

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
