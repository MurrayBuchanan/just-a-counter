//
//  AddCounterView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData

struct AddCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let collections: [CounterCollection]
    @State private var selectedCollection: CounterCollection? = nil
    @State private var name = ""
    @State private var value: Int = 0
    @State private var dailyIncrement = 0
    @State private var step: Int = 1
    @State private var iconName: String? = "plus.square"
    @State private var selectedThemeName: String = "blue"
    @State private var selectedLayout: CounterLayoutStyle = .standard
    @State private var showingSymbolPicker = false
    @State private var customiseLayout = false
    
    // Goal-related states
    @State private var hasGoal = false
    @State private var goalValue: Int = 1
    @State private var isCountingUp = true

    @State private var showsResetButton = false
    @State private var resetToValue: Int = 0
    @State private var didConfirm = false
    @FocusState private var focusedNumberField: NumberField?

    private enum NumberField {
        case startValue, dailyIncrement, stepSize, goalValue, resetToValue
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
            .navigationTitle("New Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        addCounter()
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

    private func addCounter() {
        let counter = Counter(
            name: name,
            value: value,
            dailyIncrement: dailyIncrement,
            step: step,
            iconName: iconName,
            goalValue: hasGoal ? goalValue : nil,
            isCountingUp: hasGoal ? isCountingUp : true,
            showsResetButton: showsResetButton,
            resetToValue: resetToValue,
            themeName: selectedThemeName,
            layoutStyle: customiseLayout ? selectedLayout.rawValue : CounterLayoutStyle.standard.rawValue,
            collection: selectedCollection
        )
        context.insert(counter)
        if let collection = selectedCollection {
            var counters = collection.counters.sorted(by: { $0.order < $1.order })
            counters.append(counter)
            for (idx, c) in counters.enumerated() { c.order = idx }
            collection.counters = counters
        }
        WidgetReloader.sync(counter)
        WidgetReloader.reloadCounterWidget()
        dismiss()
    }
}

struct StepperNumberField<Field: Hashable>: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var focus: FocusState<Field?>.Binding
    let field: Field
    var showsStepper: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 8)
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 80)
                .focused(focus, equals: field)
                .onChange(of: value) { _, newValue in
                    value = min(max(newValue, range.lowerBound), range.upperBound)
                }
            if showsStepper {
                Stepper("", value: $value, in: range)
                    .labelsHidden()
            }
        }
    }
}

struct ThemeGrid: View {
    let themes: [Theme]
    @Binding var selectedThemeName: String

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(40), spacing: 16), count: 6)
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(themes.prefix(12)) { theme in
                ZStack {
                    // Selected theme circle
                    Circle()
                        .fill(selectedThemeName == theme.id ? theme.primaryColor : Color(.secondarySystemBackground))
                        .frame(width: 40, height: 40)
                        
                    // Gap circle
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 34, height: 34)
                    // Colour theme circle
                    Circle()
                        .fill(theme.gradient)
                        .frame(width: 30, height: 30)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                .onTapGesture {
                    selectedThemeName = theme.id
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddCounterView_Previews: PreviewProvider {
    static var previews: some View {
        AddCounterView(collections: [])
            .modelContainer(for: Counter.self, inMemory: true)
    }
}
