import SwiftUI

struct LifeEventEditView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Use @State for the event being edited/created
    @State private var lifeEvent: LifeEvent
    var onSave: (LifeEvent) -> Void
    
    // Track if it's a new event for title/logic
    private let isNew: Bool
    
    init(event: LifeEvent? = nil, onSave: @escaping (LifeEvent) -> Void) {
        if let existingEvent = event {
            // If editing, initialize state with existing data
            self._lifeEvent = State(initialValue: existingEvent)
            self.isNew = false
        } else {
            // If creating, initialize state with defaults
            self._lifeEvent = State(initialValue: LifeEvent(title: "", date: Date(), type: .other))
            self.isNew = true
        }
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $lifeEvent.title)
                    
                    Picker("Event Type", selection: $lifeEvent.type) {
                        ForEach(LifeEvent.EventType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    
                    DatePicker("Date", selection: $lifeEvent.date, displayedComponents: .date)
                    
                    TextField("Description (Optional)", text: Binding(
                        get: { lifeEvent.description ?? "" },
                        set: { lifeEvent.description = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Reminder (Optional)")) {
                    Picker("Remind me", selection: $lifeEvent.reminderFrequency) {
                        Text("No Reminder").tag(nil as LifeEvent.ReminderFrequency?)
                        ForEach(LifeEvent.ReminderFrequency.allCases.filter { $0 != .none }, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency as LifeEvent.ReminderFrequency?)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Add Life Event" : "Edit Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(lifeEvent)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(lifeEvent.title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    // Example usage for preview
    @State var event = LifeEvent(title: "Started New Job", date: Date(), description: "Software Engineer at Tech Corp", type: .newJob, reminderFrequency: .yearly)
    
    // Preview for adding a new event
    return LifeEventEditView(onSave: { savedEvent in
        print("Preview saved new event: \(savedEvent)")
    })
    
    // Preview for editing an existing event (uncomment to use)
    /*
    return LifeEventEditView(event: event, onSave: { savedEvent in
        print("Preview saved edited event: \(savedEvent)")
        event = savedEvent // Update the state to reflect changes in preview
    })
     */
} 