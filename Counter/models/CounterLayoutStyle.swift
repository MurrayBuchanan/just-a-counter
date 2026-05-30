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
}
