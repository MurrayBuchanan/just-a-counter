//
//  EditCounterView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData

struct EditCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var counter: Counter

    let collections: [CounterCollection]

    @State private var name: String
    @State private var value: Int
    @State private var selectedThemeName: String
    @State private var iconName: String?
    @State private var selectedLayout: CounterLayoutStyle
    @State private var selectedCollection: CounterCollection?
    @State private var showingSymbolPicker = false
    @State private var dailyIncrement: Int
    @State private var step: Int
    @State private var hasGoal: Bool
    @State private var goalValue: Int
    @State private var isCountingUp: Bool
    @State private var showsResetButton: Bool
    @State private var resetToValue: Int
    @State private var customiseLayout: Bool
    @State private var didConfirm = false
    @FocusState private var focusedNumberField: NumberField?

    private enum NumberField {
        case startValue, dailyIncrement, stepSize, goalValue, resetToValue
    }

    init(counter: Counter, collections: [CounterCollection]) {
        self.counter = counter
        self.collections = collections
        _name = State(initialValue: counter.name)
        _value = State(initialValue: counter.value)
        _selectedThemeName = State(initialValue: counter.themeName)
        _iconName = State(initialValue: counter.iconName)
        _selectedLayout = State(initialValue: counter.layout)
        _selectedCollection = State(initialValue: counter.collection)
        _dailyIncrement = State(initialValue: counter.dailyIncrement)
        _step = State(initialValue: counter.step)
        _hasGoal = State(initialValue: counter.goalValue != nil)
        _goalValue = State(initialValue: counter.goalValue ?? 1)
        _isCountingUp = State(initialValue: counter.isCountingUp)
        _showsResetButton = State(initialValue: counter.showsResetButton)
        _resetToValue = State(initialValue: counter.resetToValue)
        _customiseLayout = State(initialValue: counter.layout != .standard)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    StepperNumberField(
                        title: "Initial Value",
                        value: $value,
                        range: CounterValueBounds.range,
                        focus: $focusedNumberField,
                        field: .startValue,
                        showsStepper: false
                    )

                    StepperNumberField(
                        title: "Per Tap",
                        value: $step,
                        range: 1...100,
                        focus: $focusedNumberField,
                        field: .stepSize
                    )

                    StepperNumberField(
                        title: "Per Day",
                        value: $dailyIncrement,
                        range: 0...100,
                        focus: $focusedNumberField,
                        field: .dailyIncrement
                    )
                } header: {
                    Text("Details")
                } footer: {
                    Text("Per tap is how much + and − change the count. Per day is how much is added automatically each day.")
                }

                if !collections.isEmpty {
                    Section("Assign to Folder") {
                        Picker("Folder", selection: $selectedCollection) {
                            Text("None").tag(Optional<CounterCollection>(nil))
                            ForEach(collections.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { collection in
                                Text(collection.name).tag(Optional(collection))
                            }
                        }
                    }
                }

                Section {
                    Toggle("Set Goal", isOn: $hasGoal)

                    if hasGoal {
                        StepperNumberField(
                            title: "Target Value",
                            value: $goalValue,
                            range: 1...CounterValueBounds.max,
                            focus: $focusedNumberField,
                            field: .goalValue
                        )

                        Picker("Direction", selection: $isCountingUp) {
                            Text("Count Up").tag(true)
                            Text("Count Down").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("Goal")
                } footer: {
                    if hasGoal {
                        Text(isCountingUp
                             ? "Count up until the counter reaches the target."
                             : "Count down until the counter reaches zero.")
                    }
                }

                Section {
                    Toggle("Show Reset Button", isOn: $showsResetButton)

                    if showsResetButton {
                        StepperNumberField(
                            title: "Reset To",
                            value: $resetToValue,
                            range: CounterValueBounds.range,
                            focus: $focusedNumberField,
                            field: .resetToValue,
                            showsStepper: false
                        )
                    }
                } header: {
                    Text("Reset")
                } footer: {
                    if showsResetButton {
                        Text("A reset button appears in the navigation bar and sets the counter back to this value.")
                    }
                }

                Section {
                    Toggle("Customise Layout", isOn: $customiseLayout)

                    if customiseLayout {
                        LayoutStylePicker(selection: $selectedLayout)
                    }

                    Button {
                        showingSymbolPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = iconName {
                                Image(systemName: icon)
                                    .foregroundColor(ThemeManager.theme(for: selectedThemeName).primaryColor)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    ThemeGrid(themes: Theme.allThemes, selectedThemeName: $selectedThemeName)
                } header: {
                    Text("Design")
                }
            }
            .navigationTitle("Edit Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedNumberField = nil
                    }
                }
            }
            .sheet(isPresented: $showingSymbolPicker) {
                NavigationStack {
                    SymbolGridView(selectedSymbolName: $iconName, didConfirm: $didConfirm, navigationLabel: "Choose Icon")
                }
            }
        }
    }

    private func saveChanges() {
        counter.name = name
        counter.value = value
        counter.themeName = selectedThemeName
        counter.iconName = iconName
        counter.layout = customiseLayout ? selectedLayout : .standard
        counter.dailyIncrement = dailyIncrement
        counter.step = step
        counter.goalValue = hasGoal ? goalValue : nil
        counter.goalDate = nil
        counter.isCountingUp = hasGoal ? isCountingUp : true
        counter.showsResetButton = showsResetButton
        counter.resetToValue = resetToValue

        updateCollectionAssignment()
        WidgetReloader.sync(counter)
        WidgetReloader.reloadCounterWidget()
        dismiss()
    }

    private func updateCollectionAssignment() {
        let oldCollection = counter.collection
        let newCollection = selectedCollection

        guard oldCollection?.uuid != newCollection?.uuid else { return }

        if let oldCollection {
            var oldCounters = oldCollection.counters.sorted(by: { $0.order < $1.order })
            oldCounters.removeAll { $0.uuid == counter.uuid }
            for (idx, c) in oldCounters.enumerated() { c.order = idx }
            oldCollection.counters = oldCounters
        }

        counter.collection = newCollection

        if let newCollection {
            var newCounters = newCollection.counters.sorted(by: { $0.order < $1.order })
            if !newCounters.contains(where: { $0.uuid == counter.uuid }) {
                newCounters.append(counter)
            }
            for (idx, c) in newCounters.enumerated() { c.order = idx }
            newCollection.counters = newCounters
        }
    }
}
