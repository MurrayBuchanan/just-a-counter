//
//  SymbolGridView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct SymbolGridView: View {
    @Binding var selectedSymbolName: String?
    var name: Binding<String>? = nil
    @Binding var didConfirm: Bool
    var navigationLabel: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory = 0
    @State private var tempSelectedSymbol: String? = "plus.square"
    @State private var scrollProxy: ScrollViewProxy? = nil
    @FocusState private var nameFieldFocused: Bool
    @State private var isProgrammaticScroll = false
    @State private var isUpdatingFromScroll = false

    let categories = ["Objects", "People", "Symbols"]

    let objectSymbols = [
        "folder", "plus.square", "tray", "doc", "envelope", "laptopcomputer", "printer", "externaldrive", "mic", "message", "paperplane", "creditcard", "keyboard", "archivebox", "cube", "pencil", "paintbrush", "hammer", "wrench", "iphone", "desktopcomputer", "cart", "gift", "tag", "star", "bell", "calendar", "book", "bookmark", "camera", "car", "clock"
    ]
    let peopleSymbols = [
        "person", "person.2", "person.3", "person.crop.circle", "person.crop.square", "bubble.left", "graduationcap", "briefcase", "person.badge.plus", "person.badge.minus", "person.2.circle", "person.3.sequence", "person.crop.rectangle", "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark", "person.crop.circle.badge.exclam", "person.crop.circle.badge.questionmark", "person.icloud", "person.wave.2", "person.2.wave.2", "person.crop.artframe", "person.crop.square.filled.and.at.rectangle", "person.text.rectangle", "person.icloud"
    ]
    let symbolSymbols = [
        "star", "heart", "bolt", "flame", "moon", "cloud", "sun.max", "leaf", "flag", "bookmark", "tag", "gift", "crown", "cube", "circle", "square", "triangle", "hexagon", "diamond", "circle.grid.cross", "star.square", "heart.square", "bolt.square", "flame", "moon", "cloud", "sun.max", "leaf", "flag", "bookmark", "tag", "gift"
    ]

    var allSymbols: [String] { objectSymbols + peopleSymbols + symbolSymbols }

    var categoryRanges: [Range<Int>] {
        let objects = 0..<objectSymbols.count
        let people = objects.upperBound..<(objects.upperBound + peopleSymbols.count)
        let symbols = people.upperBound..<(people.upperBound + symbolSymbols.count)
        return [objects, people, symbols]
    }

    let rows = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)

    private let symbolSize: CGFloat = 52
    private let columnSpacing: CGFloat = 24
    private let gridPadding: CGFloat = 16
    private var columnWidth: CGFloat { symbolSize + columnSpacing }

    private func categoryIndex(forSymbolIndex index: Int) -> Int {
        let clamped = min(max(index, 0), allSymbols.count - 1)
        for (catIdx, range) in categoryRanges.enumerated() where range.contains(clamped) {
            return catIdx
        }
        return categoryRanges.count - 1
    }

    private func categoryIndex(forScrollOffset offset: CGFloat) -> Int {
        let adjusted = max(0, offset - gridPadding)
        let column = Int(adjusted / columnWidth)
        let symbolIndex = min(column * rows.count, allSymbols.count - 1)
        return categoryIndex(forSymbolIndex: symbolIndex)
    }

    private func symbolIndex(for name: String?) -> Int? {
        guard let name else { return nil }
        return allSymbols.firstIndex(of: name)
    }

    private func scrollToSymbol(at index: Int, animated: Bool) {
        isProgrammaticScroll = true
        isUpdatingFromScroll = true
        selectedCategory = categoryIndex(forSymbolIndex: index)

        let anchor = UnitPoint(x: 0.3, y: 0.5)
        let scroll = {
            scrollProxy?.scrollTo(index, anchor: anchor)
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.35), scroll)
        } else {
            scroll()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.45 : 0.15)) {
            isProgrammaticScroll = false
            isUpdatingFromScroll = false
        }
    }

    private func jumpToCategory(_ index: Int) {
        guard index >= 0, index < categories.count else { return }
        isProgrammaticScroll = true
        withAnimation(.easeInOut(duration: 0.35)) {
            scrollProxy?.scrollTo(categoryRanges[index].lowerBound, anchor: .leading)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            isProgrammaticScroll = false
        }
    }

    private func updateCategoryFromScroll(_ index: Int) {
        guard index != selectedCategory else { return }
        isUpdatingFromScroll = true
        withAnimation {
            selectedCategory = index
        }
        DispatchQueue.main.async {
            isUpdatingFromScroll = false
        }
    }

    private var symbolGrid: some View {
        GeometryReader { outerGeo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: columnSpacing) {
                        ForEach(Array(allSymbols.enumerated()), id: \.offset) { index, symbol in
                            Button {
                                tempSelectedSymbol = symbol
                            } label: {
                                ZStack {
                                    if tempSelectedSymbol == symbol {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemGray5))
                                            .frame(width: symbolSize, height: symbolSize)
                                    }
                                    Image(systemName: symbol)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: symbolSize, height: symbolSize)
                            }
                            .id(index)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(gridPadding)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.x
                } action: { _, newOffset in
                    guard !isProgrammaticScroll else { return }
                    updateCategoryFromScroll(categoryIndex(forScrollOffset: newOffset))
                }
                .onAppear {
                    scrollProxy = proxy
                    tempSelectedSymbol = selectedSymbolName ?? "plus.square"
                    if let index = symbolIndex(for: tempSelectedSymbol) {
                        DispatchQueue.main.async {
                            scrollToSymbol(at: index, animated: false)
                        }
                    }
                }
            }
            .frame(height: 4 * 44 + 3 * 24 + 32)
        }
        .frame(height: 4 * 44 + 3 * 24 + 32)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let selected = tempSelectedSymbol {
                    Image(systemName: selected)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .foregroundColor(.gray)
                        .padding(.top, 136)
                        .padding(.bottom, name != nil ? 40 : 152)
                        .fontWeight(.semibold)
                }
                if let name = name {
                    TextField("", text: name)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .focused($nameFieldFocused)
                        .padding(.bottom, 88)
                        .padding(.horizontal)
                }
                Picker("Category", selection: $selectedCategory) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        Text(categories[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedCategory) { _, newValue in
                    guard !isUpdatingFromScroll else { return }
                    jumpToCategory(newValue)
                }
                .padding(.bottom, 8)
                symbolGrid
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(navigationLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    selectedSymbolName = tempSelectedSymbol
                    didConfirm = true
                    dismiss()
                }
                .disabled(tempSelectedSymbol == nil || (name != nil && name!.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
    }
}
