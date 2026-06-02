//
//  DraggableCounterRow.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DraggableCounterRow: View {
    let counter: Counter
    let isReorderingEnabled: Bool
    let onDragStart: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var rowWidth: CGFloat = 0

    var body: some View {
        CounterRowView(counter: counter)
            .counterRowCardBackground()
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { rowWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, new in rowWidth = new }
            })
            .contextMenu {
                Button {
                    onEdit?()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Divider()

                Button {
                    UIPasteboard.general.string = "\(counter.value)"
                } label: {
                    Label("Copy Value", systemImage: "doc.on.doc")
                }

                ShareLink(item: counter.shareMessage, subject: Text(counter.name)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
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
