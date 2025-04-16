import SwiftUI

struct ContactDetailView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var contact: Contact
    @State private var showingEditSheet = false
    @State private var showingActionSheet = false
    
    init(viewModel: LienViewModel, contact: Contact) {
        self.viewModel = viewModel
        self._contact = State(initialValue: contact)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with avatar
                headerView
                
                Divider()
                
                // Time visualizations
                timeVisualizationView
                
                Divider()
                
                // Contact options
                contactOptionsView
                
                Divider()
                
                // Contact details
                contactDetailsView
                
                Divider()
                
                // Social media links
                socialMediaLinks
                
                // Notes
                if !contact.notes.isEmpty {
                    Divider()
                    
                    notesView
                }
                
                Spacer()
            }
            .padding()
        }
        .background(AppColor.primaryBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.contactStore.deleteContact(withID: contact.id)
                        // Navigate back not needed - SwiftUI handles it
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ContactEditView(viewModel: viewModel, isPresented: $showingEditSheet, contact: contact)
                    .navigationTitle("Edit Contact")
                    .onDisappear {
                        // Refresh the contact when returning from edit
                        if let updatedContact = viewModel.contactStore.contacts.first(where: { $0.id == contact.id }) {
                            contact = updatedContact
                        }
                    }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Record Interaction"),
                message: Text("How did you interact with \(contact.name)?"),
                buttons: [
                    .default(Text("In Person Meeting")) {
                        recordInteraction(.meeting)
                    },
                    .default(Text("Phone Call")) {
                        recordInteraction(.call)
                    },
                    .default(Text("Message")) {
                        recordInteraction(.message)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Component Views
    
    var headerView: some View {
        VStack(spacing: 16) {
            AvatarView(contact: contact, size: 100)
                .padding(.top)
            
            Text(contact.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColor.text)
            
            if !contact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(contact.tags, id: \.self) { tag in
                            TagView(title: tag)
                        }
                    }
                }
            }
            
            Button(action: {
                showingActionSheet = true
            }) {
                Text("Record Interaction")
                    .padding()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    
    var timeVisualizationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Perspective")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            HStack {
                // Weeks remaining visualization
                TimeRemainingView(
                    title: "Weeks Left",
                    count: viewModel.weeksRemaining(with: contact),
                    total: contact.age != nil ? (contact.lifeExpectancy - (contact.age ?? 0)) * 52 : 4160 // Default 80 years
                )
                
                // Meetings remaining visualization
                TimeRemainingView(
                    title: "Potential Meetings",
                    count: viewModel.meetingsRemaining(with: contact),
                    total: contact.age != nil ? (contact.lifeExpectancy - (contact.age ?? 0)) * 12 : 960 // Default to monthly for 80 years
                )
            }
            
            if let lastContactDate = contact.lastContactDate {
                let daysSince = Calendar.current.dateComponents([.day], from: lastContactDate, to: Date()).day ?? 0
                HStack {
                    Image(systemName: daysSince > 30 ? "exclamationmark.circle" : "checkmark.circle")
                        .foregroundColor(daysSince > 30 ? .red : .green)
                    
                    Text("Last interaction was \(daysSince) \(daysSince == 1 ? "day" : "days") ago")
                        .font(.subheadline)
                        .foregroundColor(AppColor.secondaryText)
                }
                .padding(.top, 4)
            }
        }
    }
    
    var contactOptionsView: some View {
        HStack(spacing: 20) {
            contactOptionButton(
                icon: "message",
                title: "Message",
                action: {
                    if let phone = contact.phone, let url = URL(string: "sms:\(phone)") {
                        UIApplication.shared.open(url)
                        recordInteraction(.message)
                    }
                }
            )
            
            contactOptionButton(
                icon: "phone",
                title: "Call",
                action: {
                    if let phone = contact.phone, let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                        recordInteraction(.call)
                    }
                }
            )
            
            contactOptionButton(
                icon: "calendar",
                title: "Schedule",
                action: {
                    // Default to calendar app
                    if let url = URL(string: "calshow://") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .padding(.vertical, 8)
    }
    
    func contactOptionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColor.accent)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColor.text)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColor.secondaryBackground)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var contactDetailsView: some View {
        let detailItems = getContactDetailItems()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Contact Details")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            ForEach(detailItems, id: \.title) { item in
                contactInfoRow(icon: item.icon, title: item.title, value: item.value)
            }
        }
    }
    
    private func getContactDetailItems() -> [(icon: String, title: String, value: String)] {
        var items: [(icon: String, title: String, value: String)] = [
            (icon: "person.fill", title: "Relationship", value: contact.relationshipType.rawValue),
            (icon: "calendar", title: "Contact Frequency", value: contact.meetFrequency.rawValue)
        ]
        
        if let phone = contact.phone {
            items.append((icon: "phone", title: "Phone", value: phone))
        }
        
        if let email = contact.email {
            items.append((icon: "envelope", title: "Email", value: email))
        }
        
        if let age = contact.age {
            items.append((icon: "number", title: "Age", value: "\(age)"))
        }
        
        if let birthday = contact.birthday {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            items.append((icon: "gift", title: "Birthday", value: formatter.string(from: birthday)))
        }
        
        return items
    }
    
    func contactInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(AppColor.accent)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColor.secondaryText)
                
                Text(value)
                    .foregroundColor(AppColor.text)
            }
        }
        .padding(.vertical, 4)
    }
    
    var socialMediaLinks: some View {
        let allSocialLinks = getSocialMediaLinks()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Social Media")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            if allSocialLinks.isEmpty {
                Text("No social media links added")
                    .foregroundColor(AppColor.secondaryText)
                    .italic()
            } else {
                VStack(spacing: 0) {
                    ForEach(allSocialLinks, id: \.name) { social in
                        socialMediaRow(icon: social.icon, name: social.name, url: social.url)
                    }
                }
            }
        }
    }
    
    private func getSocialMediaLinks() -> [(icon: String, name: String, url: String)] {
        var allSocialLinks: [(icon: String, name: String, url: String)] = []
        
        // Add standard social media if URLs exist
        if let instagram = contact.instagram {
            allSocialLinks.append((icon: "camera", name: "Instagram", url: instagram))
        }
        if let whatsapp = contact.whatsapp {
            allSocialLinks.append((icon: "message", name: "WhatsApp", url: whatsapp))
        }
        if let facebook = contact.facebook {
            allSocialLinks.append((icon: "person.2", name: "Facebook", url: facebook))
        }
        if let twitter = contact.twitter {
            allSocialLinks.append((icon: "arrowshape.turn.up.right", name: "Twitter", url: twitter))
        }
        if let linkedin = contact.linkedin {
            allSocialLinks.append((icon: "briefcase", name: "LinkedIn", url: linkedin))
        }
        
        // Add custom social links
        for (key, value) in contact.otherSocialLinks {
            allSocialLinks.append((icon: "link", name: key, url: value))
        }
        
        return allSocialLinks
    }
    
    func socialMediaRow(icon: String, name: String, url: String) -> some View {
        Button(action: {
            viewModel.openSocialMedia(urlString: url)
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(AppColor.accent)
                
                Text(name)
                    .foregroundColor(AppColor.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColor.secondaryText)
            }
            .padding(.vertical, 8)
        }
    }
    
    var notesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            Text(contact.notes)
                .foregroundColor(AppColor.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppColor.secondaryBackground)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func recordInteraction(_ type: ContactStore.ContactInteractionType) {
        viewModel.contactStore.recordContact(for: contact.id, type: type)
        // Update our local state
        if let updatedContact = viewModel.contactStore.contacts.first(where: { $0.id == contact.id }) {
            contact = updatedContact
        }
    }
}

#Preview {
    NavigationView {
        ContactDetailView(
            viewModel: LienViewModel(),
            contact: Contact(
                name: "John Doe",
                age: 35,
                relationshipType: .friend,
                meetFrequency: .monthly,
                lastContactDate: Date().addingTimeInterval(-7 * 24 * 3600),
                notes: "Met at the conference last year. Really into photography and hiking.",
                tags: ["Friend", "Photography", "Hiking"]
            )
        )
    }
} 