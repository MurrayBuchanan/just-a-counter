//
//  CounterDuplicateNamingTests.swift
//  CounterTests
//
//  Created by Murray Buchanan on 02/06/2026.
//

import Testing
@testable import Counter

struct CounterDuplicateNamingTests {
    @Test func firstDuplicateUsesNumberTwo() {
        let name = CounterDuplicateNaming.name(forSourceName: "Olivia", existingNames: ["Olivia"])
        #expect(name == "Olivia (2)")
    }

    @Test func stripsLegacyCopySuffixes() {
        let name = CounterDuplicateNaming.name(
            forSourceName: "Olivia Copy Copy",
            existingNames: ["Olivia", "Olivia Copy", "Olivia Copy Copy", "Olivia (2)"]
        )
        #expect(name == "Olivia (3)")
    }

    @Test func skipsTakenIndices() {
        let name = CounterDuplicateNaming.name(
            forSourceName: "Josh",
            existingNames: ["Josh", "Josh (2)", "Josh (3)"]
        )
        #expect(name == "Josh (4)")
    }
}
