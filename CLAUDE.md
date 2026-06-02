# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An iOS SwiftUI counter app ("Just a Counter") with a WidgetKit home-screen widget. Users create named counters optionally grouped into folders (collections), increment/decrement them, and pin any counter to the home screen via the widget.

## Build & test

Open `Counter.xcodeproj` in Xcode. There is no SPM package — all targets are Xcode-only.

```bash
# Build (simulator)
xcodebuild -project Counter.xcodeproj -scheme Counter -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run unit tests
xcodebuild -project Counter.xcodeproj -scheme Counter -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project Counter.xcodeproj -scheme Counter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CounterTests/CounterTests test
```

CI runs `swift build` and `swift test --parallel` on `macos-latest` (`.github/workflows/swift.yml`).

## Architecture

### Targets

| Target | Purpose |
|---|---|
| `Counter` | Main app |
| `CounterWidget` | WidgetKit extension |
| `Shared/` | Code compiled into **both** targets |

### SwiftData models (`Shared/Counter.swift`)

- **`Counter`** — the core model: name, value, step, theme, layout, optional goal, optional collection FK, order index
- **`CounterCollection`** — folder that groups counters; cascade-deletes its counters' FK (not the counters themselves)
- Both use a `uuid: UUID` field as the stable identity (`var id: UUID { uuid }`); SwiftData's `persistentModelID` is not used for identity comparisons

`SharedModelContainer.shared` creates the single `ModelContainer` backed by the App Group `group.com.murrayb.Counter`, shared between the app and the widget extension.

### Widget data pipeline

The widget **cannot** open SwiftData synchronously inside a timeline provider. Instead:

1. **`CounterSnapshot`** (`Shared/CounterSnapshot.swift`) — lightweight `Codable` struct mirroring the fields the widget needs.
2. **`WidgetSnapshotStore`** (`Shared/WidgetSnapshotStore.swift`) — `[UUID: CounterSnapshot]` stored in the App Group `UserDefaults`. Reads are synchronous; this is what the widget provider calls.
3. **`CounterWidgetData`** (`Shared/CounterWidgetData.swift`) — bridge: loads a snapshot (cache-first, SwiftData fallback), adjusts values from `AdjustCounterIntent`, and warms the cache on first app launch.
4. **`WidgetReloader`** (`Shared/WidgetReloader.swift`) — debounces widget reloads (350 ms) triggered by in-app stepper changes so `WidgetCenter.reloadTimelines` isn't hammered. Also used after value commits in `CounterView`.

The widget's timeline policy is `.never`; reloads are push-only (either from `AdjustCounterIntent` in the widget itself, or from `WidgetReloader` in the app).

### Drag & drop reordering

SwiftUI's built-in `List` move is not used. Instead, `CountersListView` implements a fully custom drag/drop system:

- **`DraggableCounterRow`** — wraps `CounterRowView` with `.onDrag` (produces `NSItemProvider` carrying the counter's UUID string) and a drag preview.
- **`CounterDropModifiers`** — `CounterSectionDropModifier` and `CollectionSectionDropModifier` handle `.onDrop` at section and folder level.
- **`CounterReorder`** — pure logic for re-indexing `order` fields after a move; no SwiftData saves happen here — SwiftData auto-saves via `@Bindable` mutations.
- **`isDragLayoutActive`** — a flag gating compact layout changes; only set after the drag enters a real drop target (not during a context-menu long-press). A 500 ms cancellation timer (`scheduleDragCancellation`) handles the long-press false-trigger case.

### Themes & layout

- **`ThemeManager`** / **`Theme`** — maps a string ID (stored in `Counter.themeName`) to a `Color` and a `LinearGradient`. Themes are static; there is no user-defined colour.
- **`CounterLayoutStyle`** — `standard | wide | split | minimal` enum (persisted as `standard`, `compact`, `wide`, `minimal`), stored as `String` in `Counter.layoutStyle`.

### View hierarchy

```
ContentView                  ← @Query for collections + allCounters, owns all sheets/dialogs
  └─ CountersListView         ← pure display + drag state; receives data as props
       ├─ CounterFolderSectionView   ← one per folder + "Unassigned"
       │    └─ DraggableCounterRow  ← CounterRowView + drag + context menu
       │         └─ CounterView     ← full-screen counter (NavigationLink destination)
       ├─ AddCounterView / EditCounterView  (sheets)
       └─ AddCollectionView / EditCollectionView (sheets)
```

`ContentView` is the sole owner of `@Environment(\.modelContext)` mutations for inserts and deletes. `CounterView` and `CounterRowView` mutate `Counter` fields directly via `@Bindable`; SwiftData auto-saves.

## Key constraints

- Counter values are clamped to `0...999_999` everywhere (app and widget intents); see `CounterValueBounds` in `Shared/Counter.swift`.
- Reordering is disabled while a search query is active (`isReorderingEnabled = trimmedSearchText.isEmpty`).
- Deleting a collection unassigns its counters rather than deleting them (`counter.collection = nil` loop before `context.delete`).
- The widget snapshot cache must be kept warm: `CounterWidgetData.warmCacheIfNeeded()` is called in `ContentView.task` on first load.
