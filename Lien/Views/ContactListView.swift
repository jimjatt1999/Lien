import SwiftUI

struct ContactListView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var showingAddContact = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColor.secondaryText)
                    
                    TextField("Search contacts", text: $searchText)
                        .foregroundColor(AppColor.text)
                }
                .padding()
                .background(AppColor.secondaryBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                
                if viewModel.contactStore.contacts.isEmpty {
                    emptyStateView
                } else {
                    contactListContent
                }
            }
            .background(AppColor.primaryBackground)
            .navigationTitle("Your People")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                NavigationView {
                    ContactEditView(viewModel: viewModel, isPresented: $showingAddContact)
                        .navigationTitle("New Contact")
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(AppColor.secondaryText)
            
            Text("No contacts yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppColor.text)
            
            Text("Add your first contact to get started")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddContact = true
            }) {
                Text("Add Contact")
                    .padding()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    var contactListContent: some View {
        List {
            // Due today section
            if !viewModel.dueTodayContacts.isEmpty {
                Section(header: Text("Due Today").font(.headline)) {
                    ForEach(viewModel.dueTodayContacts) { contact in
                        NavigationLink(destination: ContactDetailView(viewModel: viewModel, contact: contact)) {
                            ContactRow(contact: contact)
                        }
                    }
                }
            }
            
            // Debug section - show all contacts
            if !viewModel.contactStore.contacts.isEmpty {
                Section(header: Text("All Contacts").font(.headline)) {
                    ForEach(viewModel.contactStore.contacts) { contact in
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            Text("Type: \(contact.relationshipType.rawValue)")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Contacts by relationship type
            ForEach(viewModel.contactGroups, id: \.0) { section, contacts in
                Section(header: Text(section).font(.headline)) {
                    let filteredContacts = filterContacts(contacts)
                    if filteredContacts.isEmpty && !searchText.isEmpty {
                        Text("No matches found")
                            .foregroundColor(AppColor.secondaryText)
                            .italic()
                    } else {
                        ForEach(filteredContacts) { contact in
                            NavigationLink(destination: ContactDetailView(viewModel: viewModel, contact: contact)) {
                                ContactRow(contact: contact)
                            }
                        }
                        .onDelete { indexSet in
                            // Find the actual indices in the full contacts array
                            let contactIDs = indexSet.map { filteredContacts[$0].id }
                            for id in contactIDs {
                                viewModel.contactStore.deleteContact(withID: id)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onChange(of: searchText) { _, newValue in
            viewModel.contactStore.searchText = newValue
        }
    }
    
    // MARK: - Helper Methods
    
    private func filterContacts(_ contacts: [Contact]) -> [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                (contact.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(contact: contact, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(AppColor.text)
                
                if let lastContactDate = contact.lastContactDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        
                        Text("Last contacted: \(contactDateFormatter.string(from: lastContactDate))")
                            .font(.caption)
                    }
                    .foregroundColor(AppColor.secondaryText)
                }
                
                if !contact.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(contact.tags, id: \.self) { tag in
                                TagView(title: tag)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var contactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    ContactListView(viewModel: LienViewModel())
} 