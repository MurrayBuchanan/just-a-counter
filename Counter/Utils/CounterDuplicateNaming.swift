//
//  CounterDuplicateNaming.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import Foundation

enum CounterDuplicateNaming {
    /// Produces `"Olivia (2)"`, `"Olivia (3)"`, … from any prior copy style (`Copy`, `Copy 2`, etc.).
    static func name(forSourceName sourceName: String, existingNames: [String]) -> String {
        let base = baseName(from: sourceName)
        let taken = Set(existingNames)
        var index = 2
        while taken.contains(numberedName(base: base, index: index)) {
            index += 1
        }
        return numberedName(base: base, index: index)
    }

    private static func baseName(from name: String) -> String {
        var trimmed = name.trimmingCharacters(in: .whitespaces)
        while true {
            if let numbered = numberedSuffixRange(in: trimmed) {
                trimmed = String(trimmed[..<numbered.lowerBound])
                continue
            }
            if let copy = copySuffixRange(in: trimmed) {
                trimmed = String(trimmed[..<copy.lowerBound])
                continue
            }
            break
        }
        return trimmed.isEmpty ? name : trimmed
    }

    private static func numberedName(base: String, index: Int) -> String {
        "\(base) (\(index))"
    }

    private static func numberedSuffixRange(in name: String) -> Range<String.Index>? {
        name.range(of: #" \(\d+\)$"#, options: .regularExpression)
    }

    private static func copySuffixRange(in name: String) -> Range<String.Index>? {
        name.range(of: #" Copy( \d+)?$"#, options: .regularExpression)
    }
}
