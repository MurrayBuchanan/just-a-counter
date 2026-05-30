//
//  CounterView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct CounterView: View {
    @Environment(\.colorScheme) var colorScheme
    @Bindable var counter: Counter
    @State private var showingProgressSheet = false
    @State private var showingInsights = false
    @State private var isGoalReached = false
    @State private var isEditingValue = false
    @State private var editedValueText = ""
    @FocusState private var isValueFieldFocused: Bool
    
    private var theme: Theme {
        ThemeManager.theme(for: counter)
    }
    
    var body: some View {
        ZStack {
            theme.gradient
                .opacity(counter.goalValue == nil || counter.value >= counter.goalValue! ? 1 : 0.7)
                .ignoresSafeArea()
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Group {
                    if isEditingValue {
                        TextField("", text: $editedValueText)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .keyboardType(.numberPad)
                            .focused($isValueFieldFocused)
                            .multilineTextAlignment(.center)
                            .fixedSize()
                    } else {
                        Button {
                            beginEditingValue()
                        } label: {
                            Text("\(counter.value)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Tap to enter a new value")
                    }
                }
                if let goal = counter.goalValue {
                    Text("/ \(goal)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.7))
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTitle(counter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    changeValue(by: -1)
                } label: {
                    Label("Decrease", systemImage: "minus")
                }
                Button {
                    changeValue(by: 1)
                } label: {
                    Label("Increase", systemImage: "plus")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    commitEditedValue()
                }
            }
        }
        .navigationBarHidden(false)
        .statusBar(hidden: true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.white)
        .onChange(of: isValueFieldFocused) { _, focused in
            if !focused && isEditingValue {
                commitEditedValue()
            }
        }
    }
    
    private func beginEditingValue() {
        editedValueText = "\(counter.value)"
        isEditingValue = true
        isValueFieldFocused = true
    }
    
    private func commitEditedValue() {
        guard isEditingValue else { return }
        isEditingValue = false
        isValueFieldFocused = false
        
        guard let newValue = Int(editedValueText.trimmingCharacters(in: .whitespaces)),
              (0...9999).contains(newValue) else { return }
        withAnimation {
            counter.value = newValue
            counter.lastUpdated = Date()
            WidgetReloader.reloadAll()
        }
    }
    
    private func changeValue(by amount: Int) {
        withAnimation {
            counter.value += amount * counter.step
            counter.lastUpdated = Date()
            WidgetReloader.reloadAll()
        }
    }
}
