//
//  CounterRowView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import UIKit

struct CounterRowView: View {
    @Bindable var counter: Counter
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var isActive = false

    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(theme.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: counter.iconName ?? "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(counter.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("\(counter.value)")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    if let goal = counter.goalValue {
                        Text("/ \(goal)")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isActive = true
            }

            Stepper(
                value: $counter.value,
                in: 0...9999,
                step: max(counter.step, 1)
            ) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: counter.value) { _, _ in
                counter.lastUpdated = Date()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: counter.value)
        .background(
            NavigationLink(destination: CounterView(counter: counter), isActive: $isActive) {
                EmptyView()
            }
            .opacity(0)
        )
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

            ShareLink(item: "\(counter.value)", subject: Text(counter.name)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } preview: {
            CounterMenuPreview(counter: counter)
        }
    }
}

#Preview {
    let counter = Counter(name: "Push-ups", value: 42, step: 1)
    return CounterRowView(counter: counter)
}
