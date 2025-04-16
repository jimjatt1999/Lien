import SwiftUI
import PhotosUI

struct SettingsView: View {
    @ObservedObject var viewModel: LienViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appManager: AppManager
    
    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var lifeExpectancy: Int
    // Store goals locally to avoid direct binding issues in ForEach
    @State private var meetingGoals: [Person.RelationshipType: Int]
    
    // State for Photo Picker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    init(viewModel: LienViewModel) {
        self.viewModel = viewModel
        self._name = State(initialValue: viewModel.userProfile.name)
        self._dateOfBirth = State(initialValue: viewModel.userProfile.dateOfBirth)
        self._lifeExpectancy = State(initialValue: viewModel.userProfile.lifeExpectancy)
        // Initialize local state for goals
        self._meetingGoals = State(initialValue: viewModel.userProfile.meetingGoals)
        // Initialize image data state from existing profile
        self._selectedImageData = State(initialValue: viewModel.userProfile.profileImageData)
    }
    
    var body: some View {
        NavigationView { // Wrap in NavigationView for title/buttons
            Form {
                Section(header: Text("Personal Information")) {
                    // Add profile image section at the top
                    profileImageSection
                    
                    LienTextField(title: "Your Name", text: $name, placeholder: "Enter your name")
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Stepper("Life Expectancy: \(lifeExpectancy) years", value: $lifeExpectancy, in: 60...120)
                }
                
                // --- Corrected Font Settings Section ---
                Section(header: Text("Appearance")) {
                    Picker("Font Design", selection: $appManager.appFontDesign) {
                        ForEach(AppFontDesign.allCases) { design in
                            Text(design.rawValue.capitalized).tag(design)
                        }
                    }
                    // Add more appearance settings here if needed (e.g., font size, width)
                }
                
                // --- Default Meeting Goals Section ---
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
                    if let url = URL(string: "https://www.zecrostudio.dev/lien/support") { // Replace with actual URL
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
            .onChange(of: selectedPhotoItem) { _, newItem in // Add onChange for PhotosPicker
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                 }
             }
        }
        // Apply font design from AppManager to the entire SettingsView
        .fontDesign(appManager.appFontDesign.swiftUIFontDesign)
    }
    
    // MARK: - Helper Views
    
    func meetingGoalRow(for type: Person.RelationshipType) -> some View {
        // Use binding to local state
        let binding = Binding<Int>(
            get: {
                // Use the static function from the Person extension for default
                meetingGoals[type] ?? Person.defaultMeetingGoal(for: type)
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
    
    // MARK: - Profile Image Section
    
    var profileImageSection: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                VStack {
                    Group {
                        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AppColor.cardBackground)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.circle") // Placeholder icon
                                        .font(.system(size: 50))
                                        .foregroundColor(AppColor.secondaryText)
                                )
                        }
                    }
                    .overlay(Circle().stroke(AppColor.accent, lineWidth: 2))
                    
                    Text("Tap to change photo")
                        .font(.caption)
                        .foregroundColor(AppColor.secondaryText)
                        .padding(.top, 4)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .listRowInsets(EdgeInsets()) // Remove default padding
        .padding(.vertical) // Add some vertical padding
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
        viewModel.userProfile.meetingGoals = meetingGoals
        // Save the selected image data
        viewModel.userProfile.profileImageData = selectedImageData
        
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
    // Provide AppManager for the preview
    SettingsView(viewModel: LienViewModel())
        .environmentObject(AppManager())
} 