//
//  FolderSectionExpansionStore.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import Foundation
import Observation

@Observable
final class FolderSectionExpansionStore {
    static let unassignedSectionKey = "folder.section.unassigned"
    private static let storageKey = "collapsedFolderSectionKeys"

    private(set) var collapsedSectionKeys: Set<String>

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        collapsedSectionKeys = Set(stored)
    }

    static func sectionKey(for collection: CounterCollection?) -> String {
        collection?.uuid.uuidString ?? unassignedSectionKey
    }

    func isExpanded(sectionKey: String) -> Bool {
        !collapsedSectionKeys.contains(sectionKey)
    }

    func setExpanded(_ expanded: Bool, sectionKey: String) {
        if expanded {
            collapsedSectionKeys.remove(sectionKey)
        } else {
            collapsedSectionKeys.insert(sectionKey)
        }
        persist()
    }

    func toggle(sectionKey: String) {
        setExpanded(!isExpanded(sectionKey: sectionKey), sectionKey: sectionKey)
    }

    private func persist() {
        UserDefaults.standard.set(Array(collapsedSectionKeys), forKey: Self.storageKey)
    }
}
