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
    @State private var socialMediaType: String = "Instagram"
    @State private var socialMediaUrl: String = ""
    @State private var customSocialLinks: [(key: String, value: String)] = []
    
    // Linking state
    @State private var showingLinkSheet = false
    @State private var personToLink: Person? = nil
    @State private var showingLabelAlert = false
    @State private var linkLabel: String = ""
    @State private var pendingLinksToAdd: [(personToLink: Person, label: String)] = []
    
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
                linkedPeopleSection
                socialMediaSection
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
            .sheet(isPresented: $showingLinkSheet) {
                SinglePersonSelectionSheet(viewModel: viewModel, currentPersonId: person.id) { selectedPerson in
                    personToLink = selectedPerson
                    linkLabel = ""
                    showingLabelAlert = true
                }
            }
            .alert("Relationship Label", isPresented: $showingLabelAlert, actions: {
                TextField("Label (e.g., Family, Colleague)", text: $linkLabel)
                Button("Save Link") {
                    if let person2 = personToLink, !linkLabel.isEmpty {
                        pendingLinksToAdd.append((personToLink: person2, label: linkLabel))
                    }
                    personToLink = nil
                }
                Button("Cancel", role: .cancel) { personToLink = nil }
            }, message: {
                Text("How is \(person.name) connected to \(personToLink?.name ?? "...")?")
            })
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
    
    private var linkedPeopleSection: some View {
        Section(header: Text("Linked People")) {
            let existingLinks = viewModel.getLinks(for: person)
            if !existingLinks.isEmpty {
                ForEach(existingLinks) { link in
                    linkRow(link: link)
                }
                .onDelete { indexSet in // Alternative way to remove
                     let linksToDelete = indexSet.map { existingLinks[$0] }
                     for link in linksToDelete {
                         viewModel.removeLink(link)
                     }
                 }
            } else {
                Text("No links added yet.").foregroundColor(.secondary)
            }
            Button(action: { showingLinkSheet = true }) {
                Label("Link to Another Person", systemImage: "link.badge.plus")
            }
        }
    }
    
    // Helper view for link row within linkedPeopleSection
    @ViewBuilder
    private func linkRow(link: RelationshipLink) -> some View {
        // Determine the *other* person in the link
        let otherPersonId = (link.person1ID == person.id) ? link.person2ID : link.person1ID
        if let otherPerson = viewModel.personStore.people.first(where: { $0.id == otherPersonId }) {
            HStack {
                Text("\(otherPerson.name) - \(link.label)")
                Spacer()
                Button(role: .destructive) {
                    viewModel.removeLink(link)
                } label: {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else {
            HStack { Text("Unknown Link").foregroundColor(.secondary) }
        }
    }
    
    private var socialMediaSection: some View {
        Section(header: Text("Social Media Links")) {
            HStack {
                Picker("Platform", selection: $socialMediaType) {
                    ForEach(socialMediaTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle()).frame(width: 120)
            }
            if socialMediaType == "Custom" {
                TextField("Platform Name", text: $socialMediaType).autocapitalization(.words)
            }
            HStack {
                TextField("URL", text: $socialMediaUrl).keyboardType(.URL).autocapitalization(.none)
                Button(action: addSocialMedia) { Image(systemName: "plus.circle.fill") }
            }
            // Standard links
            Group {
                if let instagram = person.instagram {
                    socialMediaLinkRow(type: "Instagram", url: instagram)
                }
                if let whatsapp = person.whatsapp {
                    socialMediaLinkRow(type: "WhatsApp", url: whatsapp)
                }
                if let facebook = person.facebook {
                    socialMediaLinkRow(type: "Facebook", url: facebook)
                }
                if let twitter = person.twitter {
                    socialMediaLinkRow(type: "Twitter", url: twitter)
                }
                if let linkedin = person.linkedin {
                    socialMediaLinkRow(type: "LinkedIn", url: linkedin)
                }
            }
            // Custom links
            ForEach(customSocialLinks.indices, id: \.self) { index in
                socialMediaLinkRow(
                    type: customSocialLinks[index].key,
                    url: customSocialLinks[index].value,
                    isCustom: true,
                    index: index
                )
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
    
    func socialMediaLinkRow(type: String, url: String, isCustom: Bool = false, index: Int? = nil) -> some View {
        HStack {
            Text(type)
            Spacer()
            Text(url)
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
            
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
        print("Save Person: Pending links before save: \(pendingLinksToAdd.count)")

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

        print("Save Person: Adding \(pendingLinksToAdd.count) pending links...")
        for pending in pendingLinksToAdd {
            print("Save Person: Adding link between \(person.id) (\(person.name)) and \(pending.personToLink.id) (\(pending.personToLink.name)) with label '\(pending.label)'")
            viewModel.addLink(person1: person, person2: pending.personToLink, label: pending.label)
        }
        print("Save Person: Finished adding links. Link store count: \(viewModel.linkStore.links.count)")
        
        pendingLinksToAdd = []
        
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
        let type = socialMediaType.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = socialMediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !type.isEmpty, !url.isEmpty else { return }
        
        switch type {
        case "Instagram": person.instagram = url
        case "WhatsApp": person.whatsapp = url
        case "Facebook": person.facebook = url
        case "Twitter": person.twitter = url
        case "LinkedIn": person.linkedin = url
        default: // Custom
            if !customSocialLinks.contains(where: { $0.key == type }) {
                customSocialLinks.append((key: type, value: url))
            }
        }
        
        socialMediaType = "Instagram"
        socialMediaUrl = ""
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
}

// ---- Add SinglePersonSelectionSheet View ----
struct SinglePersonSelectionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LienViewModel
    
    let currentPersonId: UUID
    var onPersonSelected: (Person) -> Void
    
    @State private var searchText: String = ""
    
    var availablePeople: [Person] {
        let existingLinkIDs = Set(viewModel.getLinks(for: Person(id: currentPersonId, name: "", relationshipType: .other, meetFrequency: .monthly)).flatMap { [$0.person1ID, $0.person2ID] })
        
        let others = viewModel.personStore.people.filter { 
             $0.id != currentPersonId && !existingLinkIDs.contains($0.id)
        }
        if searchText.isEmpty {
            return others
        } else {
            return others.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search person to link")
                
                List {
                     if availablePeople.isEmpty {
                        Text(searchText.isEmpty ? "No other people available to link." : "No matching people found.")
                            .foregroundColor(.secondary)
                     } else {
                         ForEach(availablePeople) { person in
                            Button(person.name) {
                                onPersonSelected(person)
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Person")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
// ---- End SinglePersonSelectionSheet View ----

#Preview {
    Text("Preview requires context (e.g., a wrapper view)")
} 