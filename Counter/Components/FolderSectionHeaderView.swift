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
        let header = folderHeaderRow

        if let collection, onEdit != nil || onDelete != nil {
            header.contextMenu {
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
            header
        }
    }

    private var folderHeaderRow: some View {
        Group {
            if showsDisclosureChevron, let onToggleExpansion {
                Button(action: onToggleExpansion) {
                    headerLabelRow
                }
                .buttonStyle(.plain)
            } else {
                headerLabelRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(showsDisclosureChevron ? .isButton : .isHeader)
        .accessibilityLabel(title)
        .accessibilityValue(showsDisclosureChevron ? (isExpanded ? "Expanded" : "Collapsed") : "")
        .accessibilityHint(showsDisclosureChevron ? "Double tap to \(isExpanded ? "collapse" : "expand") folder" : "")
    }

    private var headerLabelRow: some View {
        HStack(alignment: .center, spacing: 8) {
            titleContent
            if showsDisclosureChevron {
                disclosureChevron
            }
        }
        .frame(maxWidth: .infinity, minHeight: CounterGroupedListStyle.sectionHeaderMinHeight, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var titleContent: some View {
        let label = Text(title)
            .counterFolderSectionHeaderStyle()
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { headerWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, new in headerWidth = new }
            })
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
                        .counterFolderSectionHeaderStyle()
                        .padding(.horizontal, 4)
                        .frame(width: headerWidth, alignment: .leading)
                }
        } else {
            interactiveLabel
        }
    }

    private var disclosureChevron: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 24, alignment: .trailing)
            .animation(
                FolderSectionDisclosureAnimation.chevron(reduceMotion: reduceMotion),
                value: isExpanded
            )
            .accessibilityHidden(true)
            .sensoryFeedback(.selection, trigger: isExpanded)
    }
}
