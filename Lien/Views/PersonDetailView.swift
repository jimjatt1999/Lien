import SwiftUI
import EventKit // Import EventKit

// Renamed from ContactDetailView
struct PersonDetailView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var person: Person // Use @State for local mutations/refresh
    @State private var showingEditSheet = false
    @State private var showingLogInteractionSheet = false
    @State private var showingFullHistorySheet = false
    @State private var showingCalendarAlert = false // Add state for alert
    @State private var calendarAlertMessage = ""   // Add state for alert message
    @State private var showingHealthPicker = false // Add state for health picker sheet
    @State private var showContent = false // State to control transition
    // State for Time Perspective Info Alert
    @State private var showingTimeInfoAlert = false
    @State private var timeInfoAlertTitle = ""
    @State private var timeInfoAlertMessage = ""
    
    init(viewModel: LienViewModel, person: Person) {
        self.viewModel = viewModel
        self._person = State(initialValue: person)
    }
    
    var body: some View {
        ScrollView {
            // Wrap content in an outer VStack for the transition
            VStack(spacing: 20) { 
                 if showContent {
                     // Header (doesn't need separate animation? Keep outside if)
                     headerView
                         .padding(.bottom)
                     
                     // Animated Cards Section
                     VStack(spacing: 20) { // Keep original spacing
                         timeVisualizationView
                             .modifier(CardStyle())
                         
                         interactionOptionsView
                             .modifier(CardStyle())
                         
                         personDetailsView
                             .modifier(CardStyle())
                         
                         socialMediaLinks
                             .modifier(CardStyle())
                         
                         if !person.notes.isEmpty {
                             notesView
                                 .modifier(CardStyle())
                         }
                         
                         lifeEventsSection
                             .modifier(CardStyle())
                         
                         if !person.interactionHistory.isEmpty {
                             interactionHistoryView
                                 .modifier(CardStyle())
                         }
                     }
                     .transition(.opacity.animation(.easeIn(duration: 0.4))) // Apply transition here
                 }
             }
            .padding() 
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(person.name) 
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
                        viewModel.personStore.deletePerson(withID: person.id) // Use deletePerson
                        // Pop view handled by SwiftUI
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
                // Reference renamed edit view
                PersonEditView(viewModel: viewModel, isPresented: $showingEditSheet, person: person)
                    .navigationTitle("Edit Person") // Updated title
                    .onDisappear {
                        // Refresh the person data
                        if let updatedPerson = viewModel.personStore.people.first(where: { $0.id == person.id }) {
                            person = updatedPerson
                        }
                    }
            }
        }
        .sheet(isPresented: $showingLogInteractionSheet) {
            LogInteractionView(personName: person.name) { type, note, location, mood in
                // Call the updated ViewModel method, passing location
                viewModel.recordInteractionWithMood(for: person.id, type: type, note: note, location: location, mood: mood)
                // Refresh local person state after saving
                if let updatedPerson = viewModel.personStore.people.first(where: { $0.id == person.id }) {
                     person = updatedPerson
                }
            }
        }
        .sheet(isPresented: $showingFullHistorySheet) {
            InteractionHistoryView(person: person)
        }
        .sheet(isPresented: $showingHealthPicker) {
            HealthPickerView(selectedHealthStatus: $person.manualHealthOverride)
                .onDisappear {
                    viewModel.personStore.updatePerson(person)
                }
        }
        .alert(isPresented: $showingCalendarAlert) {
            Alert(title: Text("Calendar Action"), message: Text(calendarAlertMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showingTimeInfoAlert) {
            Alert(title: Text(timeInfoAlertTitle), message: Text(timeInfoAlertMessage), dismissButton: .default(Text("Got it")))
        }
        .onChange(of: viewModel.personStore.people) { _, newPeople in
            // Ensure local state updates if person is modified elsewhere
            if let updatedPerson = newPeople.first(where: { $0.id == person.id }) {
                if updatedPerson != person { // Avoid unnecessary updates
                    person = updatedPerson
                }
            }
            // Handle deletion? (If person no longer exists, view should probably be dismissed)
        }
        .onAppear { // Trigger animation when ScrollView appears
             showContent = true
         }
    }
    
    // MARK: - Component Views
    
    var headerView: some View {
        VStack(spacing: 16) {
            AvatarView(person: person, size: 100)
                .padding(.top)
            
            HStack(spacing: 8) {
                 Circle()
                    .fill(person.relationshipHealth.color)
                    .frame(width: 15, height: 15)
                 Text(person.relationshipHealth.description)
                     .font(.subheadline)
                     .foregroundColor(person.relationshipHealth.color)
                 if person.manualHealthOverride != nil {
                     Image(systemName: "hand.point.up.left.fill")
                         .font(.caption2)
                         .foregroundColor(.gray)
                 }
            }
            .padding(5)
            .background(Color.gray.opacity(0.001))
            .scaleEffect(showingHealthPicker ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingHealthPicker)
            .onTapGesture {
                 showingHealthPicker = true
             }
            
            if !person.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(person.tags, id: \.self) { tag in
                            TagView(title: tag)
                        }
                    }
                }
            }
            
            Button(action: {
                showingLogInteractionSheet = true
            }) {
                Label("Record Interaction", systemImage: "plus.circle.fill")
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
    
    var timeVisualizationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Perspective")
                .font(.headline)
            
            HStack(spacing: 15) {
                // Wrap each TimeRemainingView to make it tappable
                Button {
                     showTimeInfo(for: .weeks, person: person)
                 } label: {
                    TimeRemainingView(
                        title: "Weeks Left",
                        count: viewModel.weeksRemaining(with: person),
                        total: person.age != nil ? (person.lifeExpectancy - (person.age ?? 0)) * 52 : 4160
                    )
                }
                .buttonStyle(PlainButtonStyle()) // Use plain style to avoid button appearance
                
                Button {
                     showTimeInfo(for: .meetings, person: person)
                 } label: {
                    TimeRemainingView(
                        title: "Meetings Left",
                        count: viewModel.meetingsRemaining(with: person),
                        total: person.age != nil ? (person.lifeExpectancy - (person.age ?? 0)) * Int(person.meetFrequency.meetingsPerYear()) : 960
                    )
                }
                 .buttonStyle(PlainButtonStyle())

                Button {
                     showTimeInfo(for: .shared, person: person)
                 } label: {
                    TimeRemainingView(
                        title: "Shared Weeks",
                        count: viewModel.sharedWeeksRemaining(with: person),
                        total: min(viewModel.userProfile.yearsRemaining, person.lifeExpectancy - (person.age ?? 0)) * 52
                    )
                 }
                 .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    var interactionOptionsView: some View {
        HStack(spacing: 20) {
            // Use simplified button style
            interactionOptionButton(icon: "message.fill", title: "Message") {
                if let phone = person.phone, let url = URL(string: "sms:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }
            interactionOptionButton(icon: "phone.fill", title: "Call") {
                if let phone = person.phone, let url = URL(string: "tel:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }
            interactionOptionButton(icon: "calendar.badge.plus", title: "Schedule") {
                scheduleInteractionWithPerson()
            }
        }
    }
    
    // Simplified button style for interaction options
    func interactionOptionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppColor.accent)
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColor.text)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var personDetailsView: some View {
        let detailItems = getPersonDetailItems()
        return VStack(alignment: .leading, spacing: 12) { // Adjusted spacing
            Text("Details")
                .font(.headline)
            
            ForEach(detailItems, id: \.title) { item in
                personInfoRow(icon: item.icon, title: item.title, value: item.value)
                if item.title != detailItems.last?.title { // Add divider except for last item
                    Divider().padding(.leading, 36) // Indent divider past icon
                }
            }
        }
    }
    
    private func getPersonDetailItems() -> [(icon: String, title: String, value: String)] {
        var items: [(icon: String, title: String, value: String)] = [
            (icon: "person.fill", title: "Relationship", value: person.relationshipType.rawValue),
            (icon: "calendar.badge.clock", title: "Connect Frequency", value: person.meetFrequency.rawValue) // Updated icon
        ]
        
        if let phone = person.phone {
            items.append((icon: "phone", title: "Phone", value: phone))
        }
        
        if let email = person.email {
            items.append((icon: "envelope", title: "Email", value: email))
        }
        
        if let age = person.age { // Use computed age
            items.append((icon: "number", title: "Age", value: "\(age)"))
        }
        
        if let birthday = person.birthday {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            items.append((icon: "gift", title: "Birthday", value: formatter.string(from: birthday)))
        }
         
        if let anniversary = person.anniversary {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            items.append((icon: "sparkles", title: "Anniversary", value: formatter.string(from: anniversary))) // Added Anniversary
        }
        
        return items
    }
    
    func personInfoRow(icon: String, title: String, value: String) -> some View {
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
        return VStack(alignment: .leading, spacing: 12) { // Adjusted spacing
            Text("Social Media")
                .font(.headline)
            
            if allSocialLinks.isEmpty {
                Text("No social media links added")
                    .foregroundColor(AppColor.secondaryText)
                    .italic()
            } else {
                ForEach(allSocialLinks, id: \.name) { social in
                    socialMediaRow(icon: social.icon, name: social.name, url: social.url)
                    if social.name != allSocialLinks.last?.name { // Add divider except for last item
                        Divider().padding(.leading, 36)
                    }
                }
            }
        }
    }
    
    private func getSocialMediaLinks() -> [(icon: String, name: String, url: String)] {
        var allSocialLinks: [(icon: String, name: String, url: String)] = []
        
        if let instagram = person.instagram {
            allSocialLinks.append((icon: "camera", name: "Instagram", url: instagram))
        }
        if let whatsapp = person.whatsapp {
            allSocialLinks.append((icon: "message", name: "WhatsApp", url: whatsapp))
        }
        if let facebook = person.facebook {
            allSocialLinks.append((icon: "person.2", name: "Facebook", url: facebook))
        }
        if let twitter = person.twitter {
            allSocialLinks.append((icon: "arrowshape.turn.up.right", name: "Twitter", url: twitter))
        }
        if let linkedin = person.linkedin {
            allSocialLinks.append((icon: "briefcase", name: "LinkedIn", url: linkedin))
        }
        
        for (key, value) in person.otherSocialLinks {
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
            Text("Notes") // Simplified title
                .font(.headline)
            
            Text(person.notes)
                .font(.callout) // Use callout for notes
                .foregroundColor(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var interactionHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                 Text("Recent Interactions") // Changed title slightly
                     .font(.headline)
                 Spacer()
                 // Add Button to show full history
                 Button("View All") {
                     showingFullHistorySheet = true
                 }
                 .font(.callout)
             }
            
            // Display latest 5 interactions
            ForEach(person.interactionHistory.prefix(5)) { log in
                HStack(alignment: .top, spacing: 12) {
                    // Icon for interaction type
                    Image(systemName: log.type.iconName)
                        .font(.footnote)
                        .foregroundColor(AppColor.secondaryText)
                        .frame(width: 15, alignment: .center)
                        .padding(.top, 2) // Align icon slightly better

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.date, style: .date)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColor.secondaryText)
                            
                            // Show mood if available
                            if let mood = person.interactionMoods[log.id] {
                                Text(mood.emoji)
                                    .font(.caption)
                            }
                        }
                        
                        if let note = log.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(AppColor.text)
                                .lineLimit(3) // Limit note length preview
                        } else {
                            // Show type explicitly if no note
                            Text("Logged \(log.type.rawValue) interaction")
                                .font(.caption)
                                .foregroundColor(AppColor.secondaryText)
                                .italic()
                        }
                    }
                    Spacer() // Push content to the left
                }
                .padding(.vertical, 6)
                // Add subtle divider between entries?
                if log.id != person.interactionHistory.prefix(5).last?.id {
                     Divider().padding(.leading, 36) // Changed from 27 to 36
                }
            }
        }
    }
    
    private var lifeEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Life Events")
                    .font(.headline)
                
                Spacer()
            }
            
            if person.lifeEvents.isEmpty {
                Text("No life events recorded yet")
                    .foregroundColor(AppColor.secondaryText)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                ForEach(person.lifeEvents.sorted(by: { $0.date > $1.date })) { event in
                    lifeEventRow(event)
                    
                    if event != person.lifeEvents.sorted(by: { $0.date > $1.date }).last {
                        Divider().padding(.leading, 36)
                    }
                }
            }
        }
    }
    
    private func lifeEventRow(_ event: LifeEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.type.iconName)
                .foregroundColor(event.type.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(formatDate(event.date))
                        .font(.caption)
                        .foregroundColor(AppColor.secondaryText)
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AppColor.secondaryText)
                }
                
                if let reminder = event.reminderFrequency, reminder != .none {
                    HStack {
                        Image(systemName: "bell")
                            .font(.caption2)
                        Text("Reminder: \(reminder.rawValue)")
                            .font(.caption)
                    }
                    .foregroundColor(AppColor.accent)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Calendar Integration
    
    private func scheduleInteractionWithPerson() {
        // Check/request access first
        guard viewModel.calendarManager.hasCalendarAccess else {
            viewModel.calendarManager.requestCalendarAccess { granted, error in
                if granted {
                    self.scheduleInteractionWithPerson() // Retry if granted
                } else {
                    calendarAlertMessage = "Calendar access is required to schedule events. Please grant access in Settings."
                    showingCalendarAlert = true
                }
            }
            return
        }
        
        // Create event details
        let title = "Connect with \(person.name)"
        let startDate = Date() // Default to now, user can adjust in Calendar app
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)! // Default 1 hour duration
        
        // Call the manager to add the event
        viewModel.calendarManager.addEventToCalendar(title: title, startDate: startDate, endDate: endDate) { success, error in
            if success {
                calendarAlertMessage = "Event draft added to your calendar. You can adjust the time there."
            } else {
                calendarAlertMessage = "Failed to add event draft: \(error?.localizedDescription ?? "Unknown error")"
            }
            showingCalendarAlert = true
        }
    }
    
    // MARK: - Helper Functions
    
    // Enum to identify which time info was tapped
    private enum TimeInfoType { case weeks, meetings, shared }
    
    private func showTimeInfo(for type: TimeInfoType, person: Person) {
        switch type {
        case .weeks:
            timeInfoAlertTitle = "Weeks Left Calculation"
            timeInfoAlertMessage = "Based on the minimum of your remaining lifespan (\(viewModel.userProfile.yearsRemaining) years) and \(person.name)'s remaining lifespan (approx. \(max(0, person.lifeExpectancy - (person.age ?? 0))) years), multiplied by 52 weeks/year."
        case .meetings:
            timeInfoAlertTitle = "Meetings Left Calculation"
            timeInfoAlertMessage = "Based on the minimum remaining lifespan (as above) multiplied by the estimated meetings per year for your \(person.meetFrequency.rawValue) connection frequency goal."
        case .shared:
            timeInfoAlertTitle = "Shared Weeks Calculation"
             timeInfoAlertMessage = "Based on the minimum of your remaining lifespan (\(viewModel.userProfile.yearsRemaining) years) and \(person.name)'s remaining lifespan (approx. \(max(0, person.lifeExpectancy - (person.age ?? 0))) years), multiplied by 52 weeks/year. This represents the estimated time you both have left concurrently."
        }
        showingTimeInfoAlert = true
    }
}

// MARK: - Helpers

// View Modifier for Card Styling
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            // Add a subtle shadow
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Extend Person.InteractionType to include an icon name
extension Person.InteractionType {
    var iconName: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .call: return "phone.fill"
        case .message: return "message.fill"
        }
    }
}

#Preview {
    NavigationView {
        // Update preview
        PersonDetailView(
            viewModel: LienViewModel(),
            person: Person(
                name: "Jane Doe",
                birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
                relationshipType: Person.RelationshipType.friend,
                meetFrequency: Person.MeetFrequency.monthly,
                lastContactDate: Date().addingTimeInterval(-7 * 24 * 3600),
                notes: "Met at the conference last year.",
                tags: ["Friend", "Tech"],
                interactionHistory: [
                    InteractionLog(type: Person.InteractionType.meeting, note: "Coffee chat about project X"),
                    InteractionLog(type: Person.InteractionType.message)
                ],
                isCorePerson: true
            )
        )
    }
} 

