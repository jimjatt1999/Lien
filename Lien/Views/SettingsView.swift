import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: LienViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var lifeExpectancy: Int
    // Store goals locally to avoid direct binding issues in ForEach
    @State private var meetingGoals: [Person.RelationshipType: Int]
    
    init(viewModel: LienViewModel) {
        self.viewModel = viewModel
        self._name = State(initialValue: viewModel.userProfile.name)
        self._dateOfBirth = State(initialValue: viewModel.userProfile.dateOfBirth)
        self._lifeExpectancy = State(initialValue: viewModel.userProfile.lifeExpectancy)
        // Initialize local state for goals
        self._meetingGoals = State(initialValue: viewModel.userProfile.meetingGoals)
    }
    
    var body: some View {
        NavigationView { // Wrap in NavigationView for title/buttons
            Form {
                Section(header: Text("Personal Information")) {
                    LienTextField(title: "Your Name", text: $name, placeholder: "Enter your name")
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Stepper("Life Expectancy: \(lifeExpectancy) years", value: $lifeExpectancy, in: 60...120)
                }
                
                Section(header: Text("Default Meeting Goals")) {
                    ForEach(Person.RelationshipType.allCases, id: \.self) { type in
                        meetingGoalRow(for: type)
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: { /* Handle export */ }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { /* Handle import */ }) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion) // Use helper for version
                            .foregroundColor(AppColor.secondaryText)
                    }
                    
                    // Link to support/feedback
                    if let url = URL(string: "https://www.example.com/support") { // Replace with actual URL
                         Link(destination: url) {
                             Text("Support & Feedback")
                         }
                     }
                    
                    Button("Reset Onboarding", role: .destructive) { // Use destructive role
                        resetOnboarding()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("Cancel") {
                         presentationMode.wrappedValue.dismiss()
                     }
                 }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button("Save", action: saveSettings)
                         .disabled(!isFormValid) // Disable if invalid
                 }
             }
        }
    }
    
    // MARK: - Helper Views
    
    func meetingGoalRow(for type: Person.RelationshipType) -> some View {
        // Use binding to local state
        let binding = Binding<Int>(
            get: {
                meetingGoals[type] ?? Person.defaultMeetingGoal(for: type) // Provide default
            },
            set: { newValue in
                 meetingGoals[type] = newValue
            }
        )
        
        return HStack {
             Text(type.rawValue)
             Spacer()
             Picker("", selection: binding) {
                 Text("Never").tag(0)
                 Text("Yearly").tag(1)
                 Text("Quarterly").tag(4)
                 Text("Monthly").tag(12)
                 Text("Bi-Weekly").tag(26)
                 Text("Weekly").tag(52)
                 // Add Daily? .tag(365)
             }
             .pickerStyle(MenuPickerStyle())
         }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var appVersion: String {
         Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
     }

    // MARK: - Actions
    
    private func saveSettings() {
        guard isFormValid else { return }
        
        // Update user profile
        viewModel.userProfile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.userProfile.dateOfBirth = dateOfBirth
        viewModel.userProfile.lifeExpectancy = lifeExpectancy
        viewModel.userProfile.meetingGoals = meetingGoals // Save updated goals
        
        // Save to persistent storage
        viewModel.saveUserProfile()
        
        // Dismiss settings sheet
        presentationMode.wrappedValue.dismiss()
    }
    
    private func resetOnboarding() {
         UserDefaults.standard.set(false, forKey: "is-onboarded")
         viewModel.isOnboarded = false
         presentationMode.wrappedValue.dismiss()
     }
}

// Add default goals to Person model if needed
extension Person {
    static func defaultMeetingGoal(for type: RelationshipType) -> Int {
        switch type {
        case .closeFriend: return 12 // Monthly default
        case .family: return 12 // Monthly default
        case .friend: return 4 // Quarterly default
        default: return 1 // Yearly default
        }
    }
}

#Preview {
    SettingsView(viewModel: LienViewModel())
} 