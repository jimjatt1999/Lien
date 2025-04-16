import SwiftUI
import PhotosUI

// Renamed from ContactEditView
struct PersonEditView: View {
    @ObservedObject var viewModel: LienViewModel
    @Binding var isPresented: Bool
    
    @State private var person: Person
    @State private var isNewPerson: Bool
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    @State private var tagInput: String = ""
    @State private var socialMediaType = "Instagram" // Default selection
    @State private var socialMediaUrl = ""
    @State private var customPlatformName = "" // New state for custom platform name
    @State private var customSocialLinks: [(key: String, value: String)] = []
    
    // State for adding/managing links
    @State private var showingAddLinkSheet = false
    
    let socialMediaTypes = ["Instagram", "WhatsApp", "Facebook", "Twitter", "LinkedIn", "Custom"]
    
    init(viewModel: LienViewModel, isPresented: Binding<Bool>, person: Person? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        
        if let existingPerson = person {
            // Editing existing person
            self._person = State(initialValue: existingPerson)
            self._isNewPerson = State(initialValue: false)
            // Initialize custom links from existing data
            var links = [(key: String, value: String)]()
            for (key, value) in existingPerson.otherSocialLinks {
                links.append((key: key, value: value))
            }
            self._customSocialLinks = State(initialValue: links)
        } else {
            // Creating new person
            self._person = State(initialValue: Person(
                name: "",
                relationshipType: Person.RelationshipType.friend, // Qualify enum case
                meetFrequency: Person.MeetFrequency.monthly // Qualify enum case
            ))
            self._isNewPerson = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                contactInfoSection
                relationshipSection
                tagsSection
                socialMediaSection
                relationshipsSection
                notesSection
            }
            .navigationTitle(isNewPerson ? "New Person" : "Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: savePerson)
                        .disabled(person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // --- Sheets and Alerts --- 
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingAddLinkSheet) {
                AddLinkView(viewModel: viewModel, sourcePersonId: person.id)
            }
            // --- End Sheets and Alerts --- 
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    person.image = imageData
                }
            }
        }
    }
    
    // MARK: - Form Sections (Computed Properties)

    private var basicInfoSection: some View {
        Section(header: Text("Basic Information")) {
            profileImageSection
            LienTextField(title: "Name", text: $person.name, placeholder: "Person's name")
            DatePicker("Birthday", selection: optionalDateBinding(for: $person.birthday), displayedComponents: .date)
            DatePicker("Anniversary", selection: optionalDateBinding(for: $person.anniversary), displayedComponents: .date)
        }
    }
    
    private var contactInfoSection: some View {
        Section(header: Text("Contact Information")) {
            LienTextField(title: "Phone", text: phoneBinding, placeholder: "Phone number", keyboardType: .phonePad)
            LienTextField(title: "Email", text: emailBinding, placeholder: "Email address", keyboardType: .emailAddress)
        }
    }
    
    private var relationshipSection: some View {
        Section(header: Text("Relationship")) {
            Toggle("Core Person", isOn: $person.isCorePerson).tint(AppColor.accent)
            Picker("Type", selection: $person.relationshipType) {
                ForEach(Person.RelationshipType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            Picker("Connect Frequency", selection: $person.meetFrequency) {
                ForEach(Person.MeetFrequency.allCasesForPicker, id: \.self) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }
            if case .custom = person.meetFrequency {
                Stepper("Every \(customFrequencyDays.wrappedValue) days", value: customFrequencyDays, in: 1...365)
                    .padding(.leading)
            }
        }
    }
    
    private var tagsSection: some View {
        Section(header: Text("Tags")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Add a tag", text: $tagInput).submitLabel(.done).onSubmit { addTag() }
                    Button(action: addTag) { Image(systemName: "plus.circle.fill") }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(person.tags, id: \.self) { tag in
                            TagView(title: tag, isSelected: false, showDelete: true, onSelect: nil, onDelete: { removeTag(tag) })
                        }
                    }
                }
            }
        }
    }
    
    private var socialMediaSection: some View {
        Section(header: Text("Social Media Links")) {
            // Combined Add Section
            VStack(alignment: .leading, spacing: 8) {
                Picker("Platform", selection: $socialMediaType) {
                    ForEach(socialMediaTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                if socialMediaType == "Custom" {
                    TextField("Platform Name", text: $customPlatformName) // Use dedicated state
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 4)
                }
                
                HStack {
                    TextField("URL or Username", text: $socialMediaUrl) // Clarified placeholder
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addSocialMedia) { 
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(socialMediaUrl.isEmpty || (socialMediaType == "Custom" && customPlatformName.isEmpty))
                }
            }
            .padding(.vertical, 5)
            
            // Display existing links
            Group {
                if let instagram = person.instagram {
                    socialMediaLinkRow(type: "Instagram", platformIcon: "camera.fill", url: instagram)
                }
                if let whatsapp = person.whatsapp {
                    // Use phone number for WhatsApp URL if available, otherwise show stored string
                    let displayUrl = person.phone ?? whatsapp
                    socialMediaLinkRow(type: "WhatsApp", platformIcon: "phone.bubble.left.fill", url: displayUrl, isPhoneNumber: person.phone != nil)
                }
                if let facebook = person.facebook {
                    socialMediaLinkRow(type: "Facebook", platformIcon: "person.2.fill", url: facebook)
                }
                if let twitter = person.twitter {
                    socialMediaLinkRow(type: "Twitter", platformIcon: "at", url: twitter) // Use 'at' symbol for Twitter icon
                }
                if let linkedin = person.linkedin {
                    socialMediaLinkRow(type: "LinkedIn", platformIcon: "briefcase.fill", url: linkedin)
                }
            }
            
            // Custom links
            ForEach(customSocialLinks.indices, id: \.self) { index in
                socialMediaLinkRow(
                    type: customSocialLinks[index].key,
                    platformIcon: "link", // Generic link icon for custom
                    url: customSocialLinks[index].value,
                    isCustom: true,
                    index: index
                )
            }
        }
    }
    
    private var relationshipsSection: some View {
        Section(header: Text("Relationships")) {
            // List existing links
            ForEach(viewModel.getLinks(for: person)) { link in
                HStack {
                    // Find the other person involved in the link
                    let otherPersonId = (link.person1ID == person.id) ? link.person2ID : link.person1ID
                    if let otherPerson = viewModel.personStore.people.first(where: { $0.id == otherPersonId }) {
                        Text(otherPerson.name)
                        Spacer()
                        Text(link.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unknown Person") // Fallback if person not found
                        Spacer()
                        Text(link.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                removeLinks(at: indexSet)
            }
            
            // Button to add a new link
            Button {
                showingAddLinkSheet = true
            } label: {
                Label("Add Relationship Link", systemImage: "link.badge.plus")
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $person.notes).frame(minHeight: 100)
        }
    }
    
    // MARK: - UI Components
    
    var profileImageSection: some View {
        HStack {
            Spacer()
            Button(action: { showingImagePicker = true }) {
                let imageSize: CGFloat = 80 // Reduced size
                if let image = person.image, let uiImage = UIImage(data: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColor.accent, lineWidth: 1.5))
                } else {
                    Circle()
                        .fill(AppColor.cardBackground)
                        .frame(width: imageSize, height: imageSize)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(AppColor.accent.opacity(0.8))
                                .font(.system(size: imageSize * 0.4)) // Scaled icon size
                        )
                        .overlay(Circle().stroke(AppColor.accent, lineWidth: 1.5))
                }
            }
            Spacer()
        }
        .padding(.vertical, 0) // Reduced/Removed vertical padding
    }
    
    func socialMediaLinkRow(type: String, platformIcon: String, url: String, isCustom: Bool = false, isPhoneNumber: Bool = false, index: Int? = nil) -> some View {
        HStack {
            Image(systemName: platformIcon)
                .frame(width: 20, alignment: .center) // Ensure icon width
                .foregroundColor(AppColor.accent)
            
            Text(type)
            Spacer()
            Text(url)
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .onTapGesture { // Allow tapping URL to open
                    let urlToOpen = (isPhoneNumber ? "tel:\(url)" : url)
                    viewModel.openSocialMedia(urlString: urlToOpen)
                }
            
            Button(action: {
                removeSocialMedia(type: type, index: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Bindings Helpers
    
    private func optionalDateBinding(for state: Binding<Date?>) -> Binding<Date> {
        Binding<Date>(
            get: { state.wrappedValue ?? Date() },
            set: { newValue in
                state.wrappedValue = newValue
            }
        )
    }
    
    private var phoneBinding: Binding<String> {
        Binding(
            get: { person.phone ?? "" },
            set: { person.phone = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var emailBinding: Binding<String> {
        Binding(
            get: { person.email ?? "" },
            set: { person.email = $0.isEmpty ? nil : $0 }
        )
    }
    
    // Helper binding for the custom frequency days stepper
    private var customFrequencyDays: Binding<Int> {
        Binding<Int>(
            get: {
                if case .custom(let days) = person.meetFrequency {
                    return days
                } else {
                    return 7 // Default value if not custom
                }
            },
            set: { newValue in
                // Ensure we only set positive values and update the main state
                 if newValue > 0 {
                     person.meetFrequency = .custom(days: newValue)
                 }
            }
        )
    }
    
    // MARK: - Action Methods
    
    private func savePerson() {
        print("Save Person: Starting. Person ID: \(person.id), Name: \(person.name)")
        print("Save Person: Pending links before save: \(customSocialLinks.count)")

        person.otherSocialLinks = Dictionary(uniqueKeysWithValues: customSocialLinks)
        
        if isNewPerson {
            print("Save Person: Adding new person...")
            viewModel.personStore.addPerson(person)
            print("Save Person: Added new person. Store count: \(viewModel.personStore.people.count)")
        } else {
            print("Save Person: Updating existing person...")
            viewModel.personStore.updatePerson(person)
            print("Save Person: Updated existing person.")
        }
        let savedPersonID = viewModel.personStore.people.first { $0.id == person.id }?.id ?? UUID.init(uuidString: "00000000-0000-0000-0000-000000000000")!
        print("Save Person: Person ID after save/update in store: \(savedPersonID)")

        print("Save Person: Dismissing view.")
        isPresented = false
    }
    
    private func addTag() {
        let newTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newTag.isEmpty && !person.tags.contains(newTag) {
            person.tags.append(newTag)
            tagInput = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        person.tags.removeAll { $0 == tag }
    }
    
    private func addSocialMedia() {
        // Use customPlatformName if type is Custom
        let platform = (socialMediaType == "Custom") 
            ? customPlatformName.trimmingCharacters(in: .whitespacesAndNewlines) 
            : socialMediaType
            
        let url = socialMediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !platform.isEmpty, !url.isEmpty else { return }
        
        switch platform { // Check against the actual platform name
        case "Instagram": person.instagram = url
        case "WhatsApp": person.whatsapp = url // Store original input, might be username or number
        case "Facebook": person.facebook = url
        case "Twitter": person.twitter = url
        case "LinkedIn": person.linkedin = url
        default: // Custom
            if !customSocialLinks.contains(where: { $0.key == platform }) {
                customSocialLinks.append((key: platform, value: url))
            }
        }
        
        // Reset fields
        socialMediaType = "Instagram" // Reset picker
        customPlatformName = "" // Clear custom name field
        socialMediaUrl = "" // Clear URL field
    }
    
    private func removeSocialMedia(type: String, index: Int?) {
        switch type {
        case "Instagram": person.instagram = nil
        case "WhatsApp": person.whatsapp = nil
        case "Facebook": person.facebook = nil
        case "Twitter": person.twitter = nil
        case "LinkedIn": person.linkedin = nil
        default:
            if let idx = index, idx < customSocialLinks.count {
                customSocialLinks.remove(at: idx)
            }
        }
    }
    
    private func removeLinks(at offsets: IndexSet) {
        let linksToRemove = offsets.map { viewModel.getLinks(for: person)[$0] }
        for link in linksToRemove {
            viewModel.removeLink(link)
            // Force refresh? ViewModel should handle this via @Published
        }
    }
}

#Preview {
    Text("Preview requires context (e.g., a wrapper view)")
} 