//
//  FolderSectionHeaderView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct FolderSectionHeaderView: View {
    let title: String
    let collection: CounterCollection?
    let counters: [Counter]
    let isReorderingEnabled: Bool
    let isDragging: Bool
    let isCounterDragActive: Bool
    var onDropOnHeader: (() -> Void)?
    var onDragStart: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        let titleLabel = folderTitleLabel

        if let collection, onEdit != nil || onDelete != nil {
            titleLabel.contextMenu {
                if let onEdit {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        } else {
            titleLabel
        }
    }

    @ViewBuilder
    private var folderTitleLabel: some View {
        let label = Text(title)
            .font(.subheadline)
            .fontWeight(.regular)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(isDragging ? 0.35 : 1)
            .scaleEffect(isDragging ? 0.97 : 1, anchor: .center)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDragging)

        let interactiveLabel = label
            .modifier(CounterHeaderDropBlockModifier(
                active: isReorderingEnabled && isCounterDragActive,
                onDropOnHeader: { onDropOnHeader?() }
            ))

        if isReorderingEnabled, collection != nil, let onDragStart {
            interactiveLabel
                .onDrag {
                    onDragStart()
                    return NSItemProvider(object: collection!.uuid.uuidString as NSString)
                }
        } else {
            interactiveLabel
        }
    }
}
