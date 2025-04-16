import SwiftUI

struct LogInteractionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let personName: String
    
    // State for the view
    @State private var interactionType: Person.InteractionType = .meeting // Default selection
    @State private var interactionNote: String = ""
    @State private var selectedMood: Mood? = nil
    @State private var location: String = "" // Add state for location
    
    // Callback to pass data back (updated to include location and mood)
    var onSave: (Person.InteractionType, String?, String?, Mood?) -> Void // Add String? for location
    
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
                    
                    // Conditionally show Location field
                    if interactionType == .meeting {
                        TextField("Location (Optional)", text: $location)
                    }
                }
                
                Section(header: Text("How did it make you feel?")) {
                    HStack(spacing: 15) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            VStack {
                                Text(mood.emoji)
                                    .font(.system(size: 26))
                                    .opacity(selectedMood == mood ? 1.0 : 0.6)
                                
                                Text(mood.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedMood == mood ? mood.color : .secondary)
                            }
                            .padding(12)
                            .background(
                                selectedMood == mood ?
                                    RoundedRectangle(cornerRadius: 12).fill(mood.color.opacity(0.2)) :
                                    RoundedRectangle(cornerRadius: 12).fill(Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture {
                                selectedMood = mood
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
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
            .navigationTitle("Log Interaction with \(personName)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveAndDismiss() {
        let noteToSave = interactionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationToSave = location.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(interactionType,
               noteToSave.isEmpty ? nil : noteToSave,
               locationToSave.isEmpty ? nil : locationToSave,
               selectedMood)
        presentationMode.wrappedValue.dismiss()
    }
}

// Simple Preview
#Preview {
    LogInteractionView(personName: "Preview Person") { type, note, location, mood in
        print("Save tapped: \(type.rawValue), Note: \(note ?? "None"), Location: \(location ?? "None"), Mood: \(mood?.rawValue ?? "None")")
    }
} 