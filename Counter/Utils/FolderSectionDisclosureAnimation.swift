//
//  FolderSectionDisclosureAnimation.swift
//  Counter
//
//  Created by Murray Buchanan on 02/06/2026.
//

import SwiftUI

enum FolderSectionDisclosureAnimation {
    /// Matches UITableView-style section expand/collapse timing.
    static let duration: TimeInterval = 0.38

    static func expandCollapse(reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return .linear(duration: 0.15)
        }
        return .smooth(duration: duration, extraBounce: 0)
    }

    static func chevron(reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return .linear(duration: 0.15)
        }
        return .smooth(duration: duration * 0.9, extraBounce: 0)
    }
}
