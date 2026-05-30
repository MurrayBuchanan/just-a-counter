//
//  MenuPreviewViews.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct FolderMenuPreview: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.regular)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(MenuPreviewBackground())
    }
}

struct CounterMenuPreview: View {
    let counter: Counter

    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }

    var body: some View {
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
                if let goal = counter.goalValue {
                    Text("/ \(goal)")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MenuPreviewBackground())
    }
}

struct MenuPreviewBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }
}
