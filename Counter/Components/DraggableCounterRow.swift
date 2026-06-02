//
//  DraggableCounterRow.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DraggableCounterRow: View {
    @Bindable var counter: Counter
    let collections: [CounterCollection]
    let isReorderingEnabled: Bool
    let onDragStart: () -> Void
    var onEdit: (() -> Void)? = nil
    var onMove: ((CounterCollection?) -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var rowWidth: CGFloat = 0

    private var sortedCollections: [CounterCollection] {
        collections.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        CounterRowView(counter: counter)
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { rowWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, new in rowWidth = new }
            })
            .contextMenu {
                ControlGroup {
                    ShareLink(item: counter.shareMessage, subject: Text(counter.name)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Menu {
                        Button {
                            onMove?(nil)
                        } label: {
                            Label("None", systemImage: "tray")
                        }
                        ForEach(sortedCollections) { collection in
                            Button {
                                onMove?(collection)
                            } label: {
                                Text(collection.name)
                            }
                        }
                    } label: {
                        Label("Move", systemImage: "folder")
                    }

                    Button(role: .destructive) {
                        onDelete?()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Divider()

                if let onEdit {
                    Button(action: onEdit) {
                        Label("Edit Counter", systemImage: "pencil")
                    }
                    Divider()
                }

                Button {
                    UIPasteboard.general.string = "\(counter.value)"
                } label: {
                    Label("Copy Value", systemImage: "doc.on.doc")
                }

                Button {
                    onDuplicate?()
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Button {
                    counter.isLocked.toggle()
                    WidgetReloader.sync(counter)
                } label: {
                    Label(
                        counter.isLocked ? "Unlock" : "Lock",
                        systemImage: counter.isLocked ? "lock.open" : "lock"
                    )
                }
            }
            .modifier(CounterDragModifier(
                counter: counter,
                isReorderingEnabled: isReorderingEnabled,
                onDragStart: onDragStart,
                rowWidth: rowWidth
            ))
    }
}

struct CounterDragModifier: ViewModifier {
    let counter: Counter
    let isReorderingEnabled: Bool
    let onDragStart: () -> Void
    let rowWidth: CGFloat

    func body(content: Content) -> some View {
        if isReorderingEnabled {
            content.onDrag {
                onDragStart()
                return NSItemProvider(object: counter.uuid.uuidString as NSString)
            } preview: {
                CounterRowView(counter: counter)
                    .counterRowCardBackground()
                    .frame(width: rowWidth, height: CounterRowMetrics.rowStride)
                    .padding(4)
            }
        } else {
            content
        }
    }
}
