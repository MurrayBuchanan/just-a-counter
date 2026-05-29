import SwiftUI

struct EditCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: CounterCollection
    @State private var name: String

    init(collection: CounterCollection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        collection.name = name
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
