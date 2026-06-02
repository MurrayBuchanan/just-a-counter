//
//  CounterLayoutStyle.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import Foundation

enum CounterLayoutStyle: String, CaseIterable, Identifiable, Codable {
    case standard
    case compact
    case wide
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .compact:  "Compact"
        case .wide:     "Wide"
        case .minimal:  "Minimal"
        }
    }

    /// Asset catalog name for the picker thumbnail image.
    var imageName: String { "layout.\(rawValue)" }

    /// SF Symbol shown in the picker when no custom image asset exists.
    var systemImage: String {
        switch self {
        case .standard: "list.bullet"
        case .compact:  "list.dash"
        case .wide:     "rectangle.grid.1x2.fill"
        case .minimal:  "text.alignleft"
        }
    }

}
