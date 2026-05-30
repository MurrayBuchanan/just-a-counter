//
//  ThemeManager.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct Theme: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color

    static let allThemes: [Theme] = [
        Theme(id: "blue",   name: "Blue",   color: .blue),
        Theme(id: "indigo", name: "Indigo", color: .indigo),
        Theme(id: "purple", name: "Purple", color: .purple),
        Theme(id: "pink",   name: "Pink",   color: .pink),
        Theme(id: "red",    name: "Red",    color: .red),
        Theme(id: "orange", name: "Orange", color: .orange),
        Theme(id: "yellow", name: "Yellow", color: .yellow),
        Theme(id: "green",  name: "Green",  color: .green),
        Theme(id: "teal",   name: "Teal",   color: .teal),
        Theme(id: "mint",   name: "Mint",   color: .mint),
        Theme(id: "gray",   name: "Gray",   color: .gray),
        Theme(id: "brown",  name: "Brown",  color: .brown),
    ]

    static func theme(for identifier: String) -> Theme {
        allThemes.first(where: { $0.id == identifier }) ?? allThemes[0]
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.darkened(by: 0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var primaryColor: Color { color }
}

enum ThemeManager {
    static func theme(for counter: Counter) -> Theme {
        Theme.theme(for: counter.themeName)
    }

    static func theme(for id: String) -> Theme {
        Theme.theme(for: id)
    }

    static func randomTheme() -> Theme {
        Theme.allThemes.randomElement() ?? Theme.allThemes[0]
    }
}

private extension Color {
    func darkened(by amount: Double) -> Color {
        if #available(iOS 18.0, macOS 15.0, *) {
            return mix(with: .black, by: amount)
        }
        return opacity(1.0 - amount * 0.5)
    }
}
