import SwiftUI

struct EditCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: CounterCollection
    @State private var name: String
    @State private var iconName: String?
    @State private var showingSymbolPicker = false
    @State private var didConfirm = false

    init(collection: CounterCollection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
        _iconName = State(initialValue: collection.iconName)
    }

    var body: some View {
        Form {
            Section(header: Text("Collection Name")) {
                TextField("Name", text: $name)
            }
            Section(header: Text("Icon")) {
                Button {
                    showingSymbolPicker = true
                } label: {
                    HStack {
                        Text("Icon")
                        Spacer()
                        if let icon = iconName {
                            Image(systemName: icon)
                                .foregroundColor(.accentColor)
                        } else {
                            Text("None")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Collection")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                    dismiss()
                }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showingSymbolPicker) {
            NavigationStack {
                SymbolGridView(selectedSymbolName: $iconName, didConfirm: $didConfirm)
            }
        }
    }

    private func saveChanges() {
        collection.name = name
        collection.iconName = iconName
    }
} 