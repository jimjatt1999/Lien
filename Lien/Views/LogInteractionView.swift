import SwiftUI

struct LogInteractionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let personName: String
    
    // State for the view
    @State private var interactionType: Person.InteractionType = .meeting // Default selection
    @State private var interactionNote: String = ""
    
    // Callback to pass data back
    var onSave: (Person.InteractionType, String?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Interaction Type")) {
                    Picker("Type", selection: $interactionType) {
                        ForEach(Person.InteractionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle()) // Use segmented control for few options
                }
                
                Section(header: Text("Note (Optional)")) {
                    TextEditor(text: $interactionNote)
                        .frame(minHeight: 100, maxHeight: 200) // Set reasonable height
                }
                
                Section {
                    Button(action: saveAndDismiss) {
                        Text("Save Interaction")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(PrimaryButtonStyle()) // Use existing style if available
                }
            }
            .navigationTitle("Log Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveAndDismiss() {
        let noteToSave = interactionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(interactionType, noteToSave.isEmpty ? nil : noteToSave)
        presentationMode.wrappedValue.dismiss()
    }
}

// Simple Preview
#Preview {
    LogInteractionView(personName: "Preview Person") { type, note in
        print("Save tapped: \(type.rawValue), Note: \(note ?? "None")")
    }
} 