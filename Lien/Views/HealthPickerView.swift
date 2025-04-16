import SwiftUI

struct HealthPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedHealthStatus: Person.RelationshipHealthStatus? // Binding to the override property

    // Use all cases for the picker, including 'Automatic'
    let allOptions = Person.RelationshipHealthStatus.allCases
    
    // Store the initial value to compare on save
    private let initialValue: Person.RelationshipHealthStatus?
    
    init(selectedHealthStatus: Binding<Person.RelationshipHealthStatus?>) {
        self._selectedHealthStatus = selectedHealthStatus
        self.initialValue = selectedHealthStatus.wrappedValue // Store initial state
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Health Status", selection: $selectedHealthStatus) {
                     Text("Use Automatic").tag(nil as Person.RelationshipHealthStatus?) // Use nil to represent clearing override
                     Divider()
                     ForEach(Person.RelationshipHealthStatus.selectableCases, id: \.self) { status in
                        Text(status.rawValue).tag(status as Person.RelationshipHealthStatus?)
                    }
                }
                .pickerStyle(.inline) // Or .wheel
                .labelsHidden()
                
                Spacer() // Push picker up
            }
            .padding()
            .navigationTitle("Set Relationship Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Revert to initial value if cancelled
                        selectedHealthStatus = initialValue
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Value is already updated via binding
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    struct PreviewWrapper: View {
        // Start with no override
        @State var health: Person.RelationshipHealthStatus? = nil 
        
        var body: some View {
            VStack {
                // Display current selection for preview
                 Text("Selected: \(health?.rawValue ?? "Automatic")")
                     .padding()
                
                // Provide a button to show the sheet in preview
                // (or just show HealthPickerView directly)
                HealthPickerView(selectedHealthStatus: $health)
            }
        }
    }
    return PreviewWrapper()
} 