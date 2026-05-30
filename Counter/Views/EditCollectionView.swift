//
//  EditCollectionView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct EditCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: CounterCollection
    @State private var name: String

    init(collection: CounterCollection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("Edit Folder")
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
            }
        }
    }

    private func saveChanges() {
        collection.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
