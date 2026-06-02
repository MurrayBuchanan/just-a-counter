//
//  CounterLayoutStyle.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import Foundation

enum CounterLayoutStyle: String, CaseIterable, Identifiable, Codable {
    case standard
    case wide = "compact"
    case split = "wide"
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .wide:     "Wide"
        case .split:    "Split"
        case .minimal:  "Minimal"
        }
    }

    /// Asset catalog name for the picker thumbnail image.
    var imageName: String { "layout.\(rawValue)" }

    /// SF Symbol shown in the picker when no custom image asset exists.
    var systemImage: String {
        switch self {
        case .standard: "list.bullet"
        case .wide:     "list.dash"
        case .split:    "rectangle.grid.1x2.fill"
        case .minimal:  "text.alignleft"
        }
    }

}
