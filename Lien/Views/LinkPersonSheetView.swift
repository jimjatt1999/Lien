import SwiftUI

struct LinkPersonSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LienViewModel
    
    let currentPersonId: UUID
    @Binding var selectedIDs: Set<UUID> // Use a Set for efficient multi-select tracking
    
    @State private var searchText: String = ""
    
    var availablePeople: [Person] {
        // Filter out the current person and apply search
        let others = viewModel.personStore.people.filter { $0.id != currentPersonId }
        if searchText.isEmpty {
            return others
        } else {
            return others.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search people to link") // Reusable search bar if available, or simple TextField
                
                List {
                    ForEach(availablePeople) { person in
                        HStack {
                            Text(person.name)
                            Spacer()
                            if selectedIDs.contains(person.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle()) // Make entire row tappable
                        .onTapGesture {
                            toggleSelection(for: person.id)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Link People")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                                trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

// Simple SearchBar for filtering (can be extracted later)
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            if !text.isEmpty {
                Button(action: { self.text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Preview requires passing a binding
struct LinkPersonSheetView_Previews: PreviewProvider {
    @State static var previewSelectedIDs: Set<UUID> = []
    static let previewVM = LienViewModel()

    static var previews: some View {
        // Add sample data to VM for preview
        let person1 = Person(name: "Alice", relationshipType: .friend, meetFrequency: .monthly)
        let person2 = Person(name: "Bob", relationshipType: .family, meetFrequency: .weekly, isCorePerson: true)
        let person3 = Person(name: "Charlie", relationshipType: .colleague, meetFrequency: .quarterly)
        previewVM.personStore.people = [person1, person2, person3]
        previewSelectedIDs.insert(person2.id) // Pre-select Bob
        
        return LinkPersonSheetView(viewModel: previewVM,
                                   currentPersonId: person1.id, // Linking from Alice's perspective
                                   selectedIDs: $previewSelectedIDs)
    }
} 