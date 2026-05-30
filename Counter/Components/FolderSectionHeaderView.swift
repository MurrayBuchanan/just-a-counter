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
    @Binding var isTargeted: Bool
    var onDrop: (([NSItemProvider]) -> Bool)?
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
            } preview: {
                FolderMenuPreview(title: title)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .opacity(isDragging ? 0.35 : 1)
            .scaleEffect(isDragging ? 0.97 : 1, anchor: .center)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDragging)

        let withDrop: some View = Group {
            if let onDrop {
                label
                    .onDrop(of: [.text], isTargeted: $isTargeted, perform: { providers in
                        onDrop(providers)
                    })
                    .onChange(of: isTargeted) { _, newValue in
                        if newValue {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            } else {
                label
            }
        }

        if isReorderingEnabled, collection != nil, let onDragStart {
            withDrop
                .onDrag {
                    onDragStart()
                    return NSItemProvider(object: collection!.uuid.uuidString as NSString)
                } preview: {
                    FolderMenuPreview(title: title)
                }
        } else {
            withDrop
        }
    }
}
