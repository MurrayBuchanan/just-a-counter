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
    let isDragging: Bool
    let isReorderingEnabled: Bool
    let onDragStart: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        CounterRowView(counter: counter, onEdit: onEdit, onDelete: onDelete)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
            .opacity(isDragging ? 0.35 : 1)
            .scaleEffect(isDragging ? 0.97 : 1, anchor: .center)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDragging)
            .modifier(CounterDragModifier(
                counter: counter,
                isReorderingEnabled: isReorderingEnabled,
                onDragStart: onDragStart
            ))
    }
}

struct CounterDragModifier: ViewModifier {
    let counter: Counter
    let isReorderingEnabled: Bool
    let onDragStart: () -> Void

    func body(content: Content) -> some View {
        if isReorderingEnabled {
            content
                .onDrag {
                    onDragStart()
                    return NSItemProvider(object: counter.uuid.uuidString as NSString)
                } preview: {
                    CounterMenuPreview(counter: counter)
                }
        } else {
            content
        }
    }
}
