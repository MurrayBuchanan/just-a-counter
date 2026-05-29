import SwiftUI

struct EditCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: CounterCollection
    @State private var name: String
    @State private var iconName: String?
    @State private var didConfirm = false

    init(collection: CounterCollection) {
        self.collection = collection
        _name = State(initialValue: collection.name)
        _iconName = State(initialValue: collection.iconName)
    }

    var body: some View {
        VStack {
            SymbolGridView(selectedSymbolName: $iconName, name: $name, didConfirm: $didConfirm, confirmButtonLabel: "Save", navigationLabel: "Edit Collection")
                .onChange(of: didConfirm) { newValue in
                    if newValue {
                        saveChanges()
                        dismiss()
                    }
                }
        }
    }

    private func saveChanges() {
        collection.name = name
        collection.iconName = iconName
    }
} 
