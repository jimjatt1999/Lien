import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: LienViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var lifeExpectancy: Int
    
    init(viewModel: LienViewModel) {
        self.viewModel = viewModel
        self._name = State(initialValue: viewModel.userProfile.name)
        self._dateOfBirth = State(initialValue: viewModel.userProfile.dateOfBirth)
        self._lifeExpectancy = State(initialValue: viewModel.userProfile.lifeExpectancy)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                LienTextField(title: "Your Name", text: $name, placeholder: "Enter your name")
                
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                
                Stepper("Life Expectancy: \(lifeExpectancy) years", value: $lifeExpectancy, in: 60...120)
            }
            
            Section(header: Text("Meeting Goals")) {
                ForEach(Contact.RelationshipType.allCases, id: \.self) { type in
                    meetingGoalRow(for: type)
                }
            }
            
            Section(header: Text("Export/Import")) {
                Button(action: {
                    // Handle export action
                }) {
                    Label("Export Contacts", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    // Handle import action
                }) {
                    Label("Import Contacts", systemImage: "square.and.arrow.down")
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppColor.secondaryText)
                }
                
                Button(action: {
                    if let url = URL(string: "https://linktr.ee/yourusername") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Support & Feedback")
                }
                
                Button(action: {
                    // Reset onboarding
                    UserDefaults.standard.set(false, forKey: "is-onboarded")
                    viewModel.isOnboarded = false
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Reset Onboarding")
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button(action: saveSettings) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(AppColor.accent)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }
    
    // MARK: - Helper Views
    
    func meetingGoalRow(for type: Contact.RelationshipType) -> some View {
        let binding = Binding<Int>(
            get: {
                viewModel.userProfile.meetingGoals[type] ?? 0
            },
            set: { newValue in
                var updatedGoals = viewModel.userProfile.meetingGoals
                updatedGoals[type] = newValue
                viewModel.userProfile.meetingGoals = updatedGoals
            }
        )
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(type.rawValue)
                .font(.headline)
            
            HStack {
                Text("Meet ")
                
                Picker("", selection: binding) {
                    Text("Yearly").tag(1)
                    Text("Quarterly").tag(4)
                    Text("Monthly").tag(12)
                    Text("Bi-weekly").tag(26)
                    Text("Weekly").tag(52)
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private func saveSettings() {
        // Update user profile
        viewModel.userProfile.name = name
        viewModel.userProfile.dateOfBirth = dateOfBirth
        viewModel.userProfile.lifeExpectancy = lifeExpectancy
        
        // Save to persistent storage
        viewModel.saveUserProfile()
        
        // Dismiss settings sheet
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SettingsView(viewModel: LienViewModel())
} 