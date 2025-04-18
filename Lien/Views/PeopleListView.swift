import SwiftUI
import Contacts

// Renamed from ContactListView
struct PeopleListView: View {
    @ObservedObject var viewModel: LienViewModel
    @ObservedObject var personStore: PersonStore // Directly observe PersonStore
    @State private var showingAddPerson = false // Renamed state var
    @State private var showingContactPicker = false // New state for contact picker
    // Removed searchText and activeTagFilter - now managed by ViewModel
    
    // Add state for the active filter category (used by picker/logic)
    @State private var activeFilterCategory: PeopleListFilter = .all
    
    // Property to receive the initial filter
    let initialFilter: PeopleListFilter?
    
    // Initializer to receive PersonStore and optional initialFilter
    init(viewModel: LienViewModel, initialFilter: PeopleListFilter? = nil) {
        self.viewModel = viewModel
        self.personStore = viewModel.personStore // Assign store from ViewModel
        self.initialFilter = initialFilter
        
        // Set the initial state if a filter was passed
        if let filter = initialFilter {
            // Use _activeFilterCategory because self isn't fully available yet
            self._activeFilterCategory = State(initialValue: filter)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Search bar - bind to viewModel.searchText
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColor.secondaryText)
                    
                    TextField("Search people", text: $viewModel.searchText) // Bind to viewModel
                        .foregroundColor(AppColor.text)
                        .submitLabel(.search)
                }
                .padding()
                .background(AppColor.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter Picker
                Picker("Filter", selection: $activeFilterCategory) {
                    ForEach(PeopleListFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Display active tag filter if present - use viewModel.activeTagFilter
                if let activeTag = viewModel.activeTagFilter {
                    activeFilterView(tag: activeTag)
                        .padding(.top, 5)
                }
                
                if viewModel.personStore.people.isEmpty && viewModel.searchText.isEmpty && viewModel.activeTagFilter == nil {
                    emptyStateView
                } else {
                    peopleListContent
                        .padding(.top, 5)
                }
            }
            .background(AppColor.cardBackground)

            // FAB Menu Button
            Menu {
                Button {
                    showingAddPerson = true // Existing action for manual add
                } label: {
                    Label("Add Person Manually", systemImage: "person.fill.badge.plus")
                }
                
                Button {
                    // Action to show contact picker - will be added
                    showingContactPicker = true 
                } label: {
                    Label("Import from Contacts", systemImage: "person.crop.circle.badge.arrow.down")
                }
                
            } label: {
                // The FAB appearance
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(AppColor.accent))
                    .shadow(radius: 4)
                    .rotationEffect(.degrees(showingAddPerson ? 45 : 0)) // Optional: rotate icon
                    .animation(.interactiveSpring(), value: showingAddPerson)
            }
            .padding()
        }
        .navigationTitle("Your People")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddPerson) { // Sheet for manual add
             NavigationView {
                 PersonEditView(viewModel: viewModel, isPresented: $showingAddPerson)
                     .navigationTitle("New Person")
             }
         }
        // Add sheet for contact picker
        .sheet(isPresented: $showingContactPicker) {
            // Contact Picker View will go here
             ContactPickerView { selectedContacts in
                 // Handle imported contacts
                 importContacts(selectedContacts)
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
            
            Text("No people added yet") // Updated text
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppColor.text)
            
            Text("Add your first person to get started") // Updated text
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.secondaryText)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddPerson = true // Use renamed state var
            }) {
                Text("Add Person") // Updated text
                    .padding()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // Renamed from contactListContent
    var peopleListContent: some View {
        // Determine which people to show based on activeFilterCategory *before* the List
        let peopleToShow: [Person]
        switch activeFilterCategory {
        case .all:
            peopleToShow = viewModel.filteredPeople // Use the already search/tag filtered list
        case .core:
            peopleToShow = viewModel.filteredCorePeople
        case .other:
            peopleToShow = viewModel.filteredOtherPeople
        case .suggested:
            // Get suggested people, but also apply search/tag filters from viewModel
            let suggestedIds = Set(viewModel.suggestedPeopleToReachOutTo.map { $0.id })
            peopleToShow = viewModel.filteredPeople.filter { suggestedIds.contains($0.id) }
        }
        
        // Now define the List, using the pre-calculated peopleToShow
        return List {
            // Single section containing conditional content
            Section {
                if peopleToShow.isEmpty {
                    // Display message directly within the Section
                    Text(viewModel.searchText.isEmpty && viewModel.activeTagFilter == nil ? "No people match the current filter." : "No people match your search/filter.")
                        .foregroundColor(AppColor.secondaryText)
                        .italic()
                } else {
                    // Display ForEach when people exist
                    ForEach(peopleToShow) { person in // Iterate over the determined list
                        NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
                            PersonRow(person: person) { tappedTag in
                                // Set filter on ViewModel
                                if viewModel.activeTagFilter == tappedTag {
                                    viewModel.activeTagFilter = nil
                                } else {
                                    viewModel.activeTagFilter = tappedTag
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let personIDs = indexSet.map { peopleToShow[$0].id }
                        for id in personIDs {
                            // Need to find the original person object to delete from store
                            if let personToDelete = viewModel.personStore.people.first(where: { $0.id == id }) {
                                viewModel.deletePerson(personToDelete) // Use ViewModel's delete which handles links
                            }
                        }
                    }
                }
            }
            
            // REMOVED separate sections for core/other
        }
        .listStyle(InsetGroupedListStyle()) // Keep InsetGrouped for section appearance
    }
    
    // MARK: - Helper Views (Renamed from Helper Methods)
    
    // View to display the active filter tag
    private func activeFilterView(tag: String) -> some View {
        HStack {
            Text("Filtering by:")
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
            
            TagView(title: tag)
            
            Button(action: { viewModel.activeTagFilter = nil }) { // Clear filter on ViewModel
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColor.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
    
    // Removed filterContacts - logic moved to ViewModel
    
    // Add import function logic
    private func importContacts(_ contacts: [CNContact]) {
        print("DEBUG: Attempting to import \(contacts.count) contacts.")
        
        var importedCount = 0
        for contact in contacts {
            // --- Extract Data --- 
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            // Skip if no name or if person might already exist (simple check)
            if name.isEmpty || viewModel.personStore.people.contains(where: { $0.name == name && $0.phone == contact.phoneNumbers.first?.value.stringValue }) {
                 print("  - Skipping: \(name) (empty name or potential duplicate)")
                 continue // Skip this contact
            }
            
            let phone = contact.phoneNumbers.first?.value.stringValue
            let email = contact.emailAddresses.first?.value as String?
            let birthdayComponents = contact.birthday
            let birthday = birthdayComponents?.date // Convert components to Date?
            let imageData = contact.imageDataAvailable ? contact.imageData : nil

            // --- Create Person Object --- 
            // Use defaults for relationshipType and meetFrequency, user can edit later
            var newPerson = Person(
                name: name,
                birthday: birthday,
                relationshipType: .friend, // Default type
                meetFrequency: .monthly   // Default frequency
            )
            newPerson.phone = phone
            newPerson.email = email
            newPerson.image = imageData
            
            // TODO: Import anniversary if possible (requires specific keys/labels in Contacts)
            // TODO: Import tags? (Less likely to be standard)
            
            // --- Add to Store --- 
            viewModel.personStore.addPerson(newPerson)
            importedCount += 1
            print("  - Imported: \(newPerson.name)")
        }
        print("DEBUG: Successfully imported \(importedCount) contacts.")
        // TODO: Maybe show an alert to the user confirming import count?
    }
}

// MARK: - Person Row (Renamed from Contact Row)

struct PersonRow: View {
    let person: Person // Renamed from contact
    var onTagTap: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(person: person, size: 50) // Pass person
                .overlay(alignment: .bottomTrailing) {
                    // Use Relationship Health color
                    Circle()
                        .fill(person.relationshipHealth.color)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(AppColor.cardBackground, lineWidth: 1))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)
                    .fontWeight(person.isCorePerson ? .semibold : .regular) // Highlight core people
                    .foregroundColor(AppColor.text)
                
                if let lastContactDate = person.lastContactDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        
                        // Show health description instead of raw date?
                        Text(person.relationshipHealth.description) // Display Health Status
                            // Text("Last interaction: \(personDateFormatter.string(from: lastContactDate))")
                            .font(.caption)
                    }
                    .foregroundColor(AppColor.secondaryText)
                } else {
                    // Show Unknown health if never contacted
                     HStack(spacing: 4) {
                         Image(systemName: "questionmark.circle")
                            .font(.caption2)
                         Text(Person.RelationshipHealthStatus.unknown.description)
                            .font(.caption)
                     }
                    .foregroundColor(AppColor.secondaryText)
                }
                
                if !person.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(person.tags, id: \.self) { tag in
                                TagView(title: tag) {
                                    onTagTap?(tag)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Renamed from contactDateFormatter
    private var personDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    // Update preview to pass ViewModel
    PeopleListView(viewModel: LienViewModel())
} 