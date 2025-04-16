import SwiftUI

struct AddLinkView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LienViewModel
    let sourcePersonId: UUID

    @State private var selectedTargetPersonId: UUID? = nil
    @State private var linkLabel: String = ""

    // Filtered list of potential target people (excluding source person and already linked?)
    var availableTargets: [Person] {
        // First, find the source person object using the ID
        guard let sourcePerson = viewModel.personStore.people.first(where: { $0.id == sourcePersonId }) else {
            // If source person not found, return empty list
            return []
        }
        
        // Get IDs of people already linked to the source person
        let alreadyLinkedIds = Set(viewModel.getLinks(for: sourcePerson).flatMap { [$0.person1ID, $0.person2ID] })
        
        return viewModel.personStore.people.filter { person in
            // Exclude the source person themselves AND anyone already linked
            person.id != sourcePersonId && !alreadyLinkedIds.contains(person.id)
        }
    }

    var isSaveDisabled: Bool {
        selectedTargetPersonId == nil || linkLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Link Details")) {
                    Picker("Link To", selection: $selectedTargetPersonId) {
                        Text("Select Person").tag(nil as UUID?) // Placeholder
                        ForEach(availableTargets) { person in
                            Text(person.name).tag(person.id as UUID?)
                        }
                    }
                    .onChange(of: selectedTargetPersonId) { _, newValue in
                        print("DEBUG: selectedTargetPersonId changed to: \(newValue?.uuidString ?? "nil")")
                        print("DEBUG: isSaveDisabled is now: \(isSaveDisabled)")
                    }

                    TextField("Relationship Label", text: $linkLabel, prompt: Text("e.g., Friends, Family, Colleague"))
                    .onChange(of: linkLabel) { _, newValue in
                        print("DEBUG: linkLabel changed to: '\(newValue)'")
                        print("DEBUG: isSaveDisabled is now: \(isSaveDisabled)")
                    }
                }
            }
            .navigationTitle("Add Relationship Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLink()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    func saveLink() {
        guard let targetId = selectedTargetPersonId,
              // Fetch persons directly using ID - safer than relying on index or filtered list
              let sourcePerson = viewModel.personStore.people.first(where: { $0.id == sourcePersonId }),
              let targetPerson = viewModel.personStore.people.first(where: { $0.id == targetId })
        else {
            print("Error: Could not find source or target person for linking.")
            // Maybe show an alert to the user?
            return
        }

        let finalLabel = linkLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Adding link between \(sourcePerson.name) and \(targetPerson.name) with label: \(finalLabel)")
        viewModel.addLink(person1: sourcePerson, person2: targetPerson, label: finalLabel)
        presentationMode.wrappedValue.dismiss()
    }
}

// Add a basic preview
#Preview {
    // This preview needs a proper setup with a mock ViewModel
    // and people data to be fully interactive.
    struct PreviewWrapper: View {
        @StateObject var mockViewModel = LienViewModel() // Assuming default init works
        @State var isPresented = true

        var body: some View {
            // Create a dummy person to link from
            let dummyPerson = Person(name: "Source Person", relationshipType: .friend, meetFrequency: .monthly)
            
            // Add dummy data to ViewModel for preview
            let _ = mockViewModel.personStore.people = [
                dummyPerson,
                Person(name: "Target Person 1", relationshipType: .friend, meetFrequency: .monthly),
                Person(name: "Target Person 2", relationshipType: .colleague, meetFrequency: .yearly)
            ]

            return AddLinkView(viewModel: mockViewModel, sourcePersonId: dummyPerson.id)
        }
    }
    return PreviewWrapper()
} 