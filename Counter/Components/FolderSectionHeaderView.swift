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
    let isExpanded: Bool
    let showsDisclosureChevron: Bool
    let isReorderingEnabled: Bool
    let isDragging: Bool
    let isCounterDragActive: Bool
    var onToggleExpansion: (() -> Void)?
    var onDropOnHeader: (() -> Void)?
    var onDragStart: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var headerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let titleLabel = folderTitleLabel

        if let collection, onEdit != nil || onDelete != nil {
            titleLabel.contextMenu {
                if let onEdit {
                    Button(action: onEdit) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                }
                if onEdit != nil, onDelete != nil {
                    Divider()
                }
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Folder", systemImage: "trash")
                    }
                }
            }
        } else {
            titleLabel
        }
    }

    @ViewBuilder
    private var folderTitleLabel: some View {
        HStack(spacing: 6) {
            let label = Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear { headerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, new in headerWidth = new }
                })
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
                    } preview: {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .frame(width: headerWidth, height: 44, alignment: .leading)
                    }
            } else {
                interactiveLabel
            }

            if showsDisclosureChevron, let onToggleExpansion {
                Button(action: onToggleExpansion) {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(
                    FolderSectionDisclosureAnimation.chevron(reduceMotion: reduceMotion),
                    value: isExpanded
                )
                .accessibilityLabel(isExpanded ? "Collapse folder" : "Expand folder")
                .sensoryFeedback(.selection, trigger: isExpanded)
            }
        }
    }
}
