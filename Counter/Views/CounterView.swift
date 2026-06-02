//
//  CounterView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct CounterView: View {
    @Bindable var counter: Counter
    @State private var isEditingValue = false
    @State private var editedValueText = ""
    @FocusState private var isValueFieldFocused: Bool

    private var theme: Theme { ThemeManager.theme(for: counter) }

    private var goalOpacity: Double {
        counter.goalValue == nil || counter.value >= counter.goalValue! ? 1.0 : 0.7
    }

    var body: some View {
        layoutContent
            .navigationTitle(counter.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { commitEditedValue() }
                }
            }
            .statusBar(hidden: true)
            .onChange(of: isValueFieldFocused) { _, focused in
                if !focused && isEditingValue { commitEditedValue() }
            }
    }

    @ViewBuilder
    private var layoutContent: some View {
        switch counter.layout {
        case .standard: standardLayout
        case .wide:     wideLayout
        case .split:    splitLayout
        case .minimal:  minimalLayout
        }
    }

    // MARK: - Standard
    // Full gradient background; value centered; large circular +/− buttons below.

    private var standardLayout: some View {
        ZStack {
            gradientBackground
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    valueDisplay(size: 72, color: .white)
                    goalLabel(size: 32, color: .white.opacity(0.7))
                }
                Spacer()
                HStack(spacing: 52) {
                    circleButton(systemImage: "minus", foreground: .white, background: .white.opacity(0.2)) {
                        changeValue(by: -1)
                    }
                    circleButton(systemImage: "plus", foreground: .white, background: .white.opacity(0.3)) {
                        changeValue(by: 1)
                    }
                }
                .padding(.bottom, 52)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.white)
    }

    // MARK: - Wide
    // Full gradient background; value in the upper portion; two large tap buttons fill the lower portion.

    private var wideLayout: some View {
        ZStack {
            gradientBackground
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    valueDisplay(size: 72, color: .white)
                    goalLabel(size: 32, color: .white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 16) {
                    wideActionButton(systemImage: "minus") { changeValue(by: -1) }
                    wideActionButton(systemImage: "plus")  { changeValue(by: 1) }
                }
                .frame(height: 148)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.white)
    }

    // MARK: - Split
    // Full gradient background; the entire screen is split into left (−) / right (+) tap zones.
    // Value edit is triggered via the toolbar pencil so tap zones have no gesture conflicts.

    private var splitLayout: some View {
        ZStack {
            gradientBackground

            HStack(spacing: 0) {
                Button { changeValue(by: -1) } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.leading, 28)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isEditingValue)

                Button { changeValue(by: 1) } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.trailing, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isEditingValue)
            }

            // Value sits above the tap zones and does not block them
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if isEditingValue {
                    TextField("", text: $editedValueText)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .keyboardType(.numberPad)
                        .focused($isValueFieldFocused)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                } else {
                    Text("\(counter.value)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
                }
                goalLabel(size: 42, color: .white.opacity(0.7))
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { beginEditingValue() } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.white)
    }

    // MARK: - Minimal
    // Pure black background; white value and monochrome buttons; no theme color.

    private var minimalLayout: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    valueDisplay(size: 80, color: .white)
                    goalLabel(size: 36, color: .white.opacity(0.35))
                }
                Spacer()
                HStack(spacing: 52) {
                    circleButton(systemImage: "minus", foreground: .white, background: .white.opacity(0.12)) {
                        changeValue(by: -1)
                    }
                    circleButton(systemImage: "plus", foreground: .black, background: .white) {
                        changeValue(by: 1)
                    }
                }
                .padding(.bottom, 52)
                if let goal = counter.goalValue, goal > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15))
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * min(CGFloat(counter.value) / CGFloat(goal), 1))
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: counter.value)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .tint(.white)
    }

    // MARK: - Shared helpers

    private var gradientBackground: some View {
        theme.gradient
            .opacity(goalOpacity)
            .ignoresSafeArea()
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
    }

    @ViewBuilder
    private func valueDisplay(size: CGFloat, color: Color) -> some View {
        if isEditingValue {
            TextField("", text: $editedValueText)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .keyboardType(.numberPad)
                .focused($isValueFieldFocused)
                .multilineTextAlignment(.center)
                .fixedSize()
        } else {
            Button { beginEditingValue() } label: {
                Text("\(counter.value)")
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Tap to enter a new value")
        }
    }

    @ViewBuilder
    private func goalLabel(size: CGFloat, color: Color) -> some View {
        if let goal = counter.goalValue {
            Text("/ \(goal)")
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    private func wideActionButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func circleButton(systemImage: String, foreground: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 64, height: 64)
                .background(background)
                .clipShape(Circle())
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
              CounterValueBounds.range.contains(newValue) else { return }
        withAnimation {
            counter.value = newValue
            counter.lastUpdated = Date()
            WidgetReloader.scheduleReload(for: counter)
        }
    }

    private func changeValue(by amount: Int) {
        withAnimation {
            counter.value = CounterValueBounds.clamp(counter.value + amount * counter.step)
            counter.lastUpdated = Date()
            WidgetReloader.scheduleReload(for: counter)
        }
    }
}
