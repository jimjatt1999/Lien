import SwiftUI
import PhotosUI

struct ContactEditView: View {
    @ObservedObject var viewModel: LienViewModel
    @Binding var isPresented: Bool
    
    @State private var contact: Contact
    @State private var isNewContact: Bool
    @State private var selectedImage: UIImage?
    @State private var tagInput: String = ""
    @State private var socialMediaType = "Instagram"
    @State private var socialMediaUrl = ""
    @State private var showingImagePicker = false
    @State private var customSocialLinks: [(key: String, value: String)] = []
    
    private let socialMediaTypes = ["Instagram", "WhatsApp", "Facebook", "Twitter", "LinkedIn", "Custom"]
    
    init(viewModel: LienViewModel, isPresented: Binding<Bool>, contact: Contact? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        
        if let contact = contact {
            // Editing existing contact
            self._contact = State(initialValue: contact)
            self._isNewContact = State(initialValue: false)
            
            // Prepare custom social links
            var links: [(key: String, value: String)] = []
            for (key, value) in contact.otherSocialLinks {
                links.append((key: key, value: value))
            }
            self._customSocialLinks = State(initialValue: links)
        } else {
            // Creating new contact
            self._contact = State(initialValue: Contact(
                name: "",
                relationshipType: .friend,
                meetFrequency: .monthly
            ))
            self._isNewContact = State(initialValue: true)
        }
    }
    
    var body: some View {
        Form {
            // Basic information
            Section(header: Text("Basic Information")) {
                profileImageSection
                
                LienTextField(title: "Name", text: $contact.name, placeholder: "Contact name")
                
                HStack {
                    Text("Age")
                        .foregroundColor(AppColor.secondaryText)
                    Spacer()
                    TextField("Age", value: $contact.age, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                DatePicker("Birthday", selection: Binding(
                    get: { contact.birthday ?? Date() },
                    set: { contact.birthday = $0 }
                ), displayedComponents: .date)
            }
            
            // Contact Information
            Section(header: Text("Contact Information")) {
                LienTextField(title: "Phone", text: Binding(
                    get: { contact.phone ?? "" },
                    set: { contact.phone = $0.isEmpty ? nil : $0 }
                ), placeholder: "Phone number", keyboardType: .phonePad)
                
                LienTextField(title: "Email", text: Binding(
                    get: { contact.email ?? "" },
                    set: { contact.email = $0.isEmpty ? nil : $0 }
                ), placeholder: "Email address", keyboardType: .emailAddress)
            }
            
            // Relationship Information
            Section(header: Text("Relationship")) {
                Picker("Type", selection: $contact.relationshipType) {
                    ForEach(Contact.RelationshipType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                Picker("Contact Frequency", selection: $contact.meetFrequency) {
                    ForEach(Contact.MeetFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            }
            
            // Tags
            Section(header: Text("Tags")) {
                HStack {
                    TextField("Add a tag", text: $tagInput)
                        .submitLabel(.done)
                        .onSubmit {
                            addTag()
                        }
                    
                    Button(action: addTag) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(contact.tags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                    .padding(.leading, 8)
                                    .padding(.trailing, 0)
                                
                                Button(action: {
                                    removeTag(tag)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                            .background(AppColor.secondaryBackground)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Social Media
            Section(header: Text("Social Media Links")) {
                // Add social media links
                HStack {
                    Picker("Platform", selection: $socialMediaType) {
                        ForEach(socialMediaTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                }
                
                if socialMediaType == "Custom" {
                    TextField("Platform Name", text: $socialMediaType)
                        .autocapitalization(.words)
                }
                
                HStack {
                    TextField("URL", text: $socialMediaUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Button(action: addSocialMedia) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                
                // Display existing social links
                Group {
                    if let instagram = contact.instagram {
                        socialMediaLinkRow(type: "Instagram", url: instagram)
                    }
                    
                    if let whatsapp = contact.whatsapp {
                        socialMediaLinkRow(type: "WhatsApp", url: whatsapp)
                    }
                    
                    if let facebook = contact.facebook {
                        socialMediaLinkRow(type: "Facebook", url: facebook)
                    }
                    
                    if let twitter = contact.twitter {
                        socialMediaLinkRow(type: "Twitter", url: twitter)
                    }
                    
                    if let linkedin = contact.linkedin {
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
            
            // Notes
            Section(header: Text("Notes")) {
                TextEditor(text: $contact.notes)
                    .frame(minHeight: 100)
            }
            
            // Save/Cancel Buttons
            Section {
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Spacer()
                    
                    Button(isNewContact ? "Add Contact" : "Save Changes") {
                        saveContact()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldImage, newImage in
            if let image = newImage {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    contact.image = imageData
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    var profileImageSection: some View {
        HStack {
            Spacer()
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let image = contact.image, let uiImage = UIImage(data: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColor.accent, lineWidth: 2))
                } else {
                    Circle()
                        .fill(AppColor.secondaryBackground)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(AppColor.accent)
                                .font(.system(size: 40))
                        )
                        .overlay(Circle().stroke(AppColor.accent, lineWidth: 2))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    func socialMediaLinkRow(type: String, url: String, isCustom: Bool = false, index: Int? = nil) -> some View {
        HStack {
            Text(type)
                .foregroundColor(AppColor.text)
            
            Spacer()
            
            Text(url)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(AppColor.secondaryText)
            
            Button(action: {
                removeSocialMedia(type: type, isCustom: isCustom, index: index)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !contact.tags.contains(trimmedTag) {
            contact.tags.append(trimmedTag)
            tagInput = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        if let index = contact.tags.firstIndex(of: tag) {
            contact.tags.remove(at: index)
        }
    }
    
    private func addSocialMedia() {
        let trimmedUrl = socialMediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUrl.isEmpty {
            switch socialMediaType {
            case "Instagram":
                contact.instagram = trimmedUrl
            case "WhatsApp":
                contact.whatsapp = trimmedUrl
            case "Facebook":
                contact.facebook = trimmedUrl
            case "Twitter":
                contact.twitter = trimmedUrl
            case "LinkedIn":
                contact.linkedin = trimmedUrl
            default:
                // It's a custom link
                let key = socialMediaType.trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty && key != "Custom" {
                    customSocialLinks.append((key: key, value: trimmedUrl))
                }
            }
            
            // Reset input fields
            socialMediaType = "Instagram"
            socialMediaUrl = ""
        }
    }
    
    private func removeSocialMedia(type: String, isCustom: Bool, index: Int?) {
        if isCustom, let index = index {
            customSocialLinks.remove(at: index)
        } else {
            switch type {
            case "Instagram":
                contact.instagram = nil
            case "WhatsApp":
                contact.whatsapp = nil
            case "Facebook":
                contact.facebook = nil
            case "Twitter":
                contact.twitter = nil
            case "LinkedIn":
                contact.linkedin = nil
            default:
                break
            }
        }
    }
    
    private func saveContact() {
        // Update custom social links dictionary
        var otherLinks: [String: String] = [:]
        for link in customSocialLinks {
            otherLinks[link.key] = link.value
        }
        contact.otherSocialLinks = otherLinks
        
        if isNewContact {
            viewModel.contactStore.addContact(contact)
        } else {
            viewModel.contactStore.updateContact(contact)
        }
        
        isPresented = false
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ContactEditView(
            viewModel: LienViewModel(),
            isPresented: .constant(true)
        )
    }
} 