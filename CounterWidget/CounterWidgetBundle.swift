//
//  CounterWidgetBundle.swift
//  CounterWidget
//
//  Created by Murray Buchanan on 30/05/2026.
//

import WidgetKit
import SwiftUI

@main
struct CounterWidgetBundle: WidgetBundle {
    var body: some Widget {
        CounterWidget()
        CounterWidgetControl()
    }
}
