import Foundation
import SwiftUI
import Combine

class LienViewModel: ObservableObject {
    @Published var personStore = PersonStore()
    @Published var linkStore = LinkStore()
    @Published var userProfile: UserProfile
    @Published var isOnboarded: Bool
    @Published var spontaneousSuggestion: Person? = nil // State for spontaneous suggestion
    
    @Published var connectionGoals: [ConnectionGoal] = [] // Connection goals
    
    // Needed for filtering in PeopleListView
    @Published var activeTagFilter: String? = nil
    @Published var searchText: String = ""
    
    private let isOnboardedKey = "is-onboarded"
    private let connectionGoalsKey = "connection-goals" // Key for storing goals
    
    init() {
        self.userProfile = UserProfile.load()
        self.isOnboarded = UserDefaults.standard.bool(forKey: isOnboardedKey)
        self.connectionGoals = loadConnectionGoals()
        
        // Connect search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .assign(to: &personStore.$searchText)
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile() {
        UserProfile.save(userProfile)
    }
    
    func completeOnboarding() {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: isOnboardedKey)
    }
    
    // MARK: - Person Management (Renamed from Contact Management)
    
    // Renamed from suggestedContactsToReachOutTo
    var suggestedPeopleToReachOutTo: [Person] {
        personStore.peopleDueForInteraction
    }
    
    // Filtered lists for PeopleListView
    var filteredPeople: [Person] {
        var filtered = personStore.people
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText) ||
                (person.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        
        // Apply active tag filter
        if let tag = activeTagFilter {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        
        return filtered
    }
    
    var filteredCorePeople: [Person] {
        filteredPeople.filter { $0.isCorePerson }
    }
    
    var filteredOtherPeople: [Person] {
        filteredPeople.filter { !$0.isCorePerson }
    }
    
    // Renamed from contactsWithSameTag
    func peopleWithSameTag(_ tag: String) -> [Person] {
        personStore.people.filter { $0.tags.contains(tag) }
    }
    
    // Philosophical calculations for each person
    // Renamed from weeksRemaining(with: contact)
    func weeksRemaining(with person: Person) -> Int {
        // Safely handle optional age from Person struct
        let personAge = person.age ?? 30 // Default age if birthday missing
        let yearsLeft = min(userProfile.yearsRemaining, person.lifeExpectancy - personAge)
        return yearsLeft * 52
    }
    
    // Renamed from meetingsRemaining(with: contact)
    func meetingsRemaining(with person: Person) -> Int {
        let personAge = person.age ?? 30
        let years = min(userProfile.yearsRemaining, person.lifeExpectancy - personAge)
        
        // Get meetings per year from the MeetFrequency helper
        let frequencyPerYear = person.meetFrequency.meetingsPerYear()
        
        // Ensure frequency is positive to avoid non-positive results
        guard frequencyPerYear > 0 else { return 0 }
        
        return Int(Double(years) * frequencyPerYear) // Calculate based on double, then cast
    }
    
    // Calculate shared weeks remaining based on minimum lifespan
    func sharedWeeksRemaining(with person: Person) -> Int {
        let userYears = userProfile.yearsRemaining
        
        let personYears: Int
        if let age = person.age {
            personYears = max(0, person.lifeExpectancy - age) // Ensure non-negative
        } else {
            // If person's age is unknown, we can't calculate shared time accurately.
            // Return 0 or some other indicator?
            personYears = person.lifeExpectancy // Or estimate based on full expectancy? Let's use full for now.
            // Alternatively: return 0 // Or handle differently in UI
        }
        
        let minYears = min(userYears, personYears)
        return minYears * 52
    }
    
    // MARK: - Link Management Helpers (Optional, could be direct calls)
    
    func getLinks(for person: Person) -> [RelationshipLink] {
        linkStore.getLinks(for: person.id)
    }
    
    func addLink(person1: Person, person2: Person, label: String) {
        linkStore.addLink(person1ID: person1.id, person2ID: person2.id, label: label)
    }
    
    func removeLink(_ link: RelationshipLink) {
        linkStore.removeLink(id: link.id)
    }
    
    // Function to also remove links when a person is deleted
    func deletePerson(_ person: Person) {
        linkStore.removeLinks(involving: person.id) // Remove related links
        personStore.deletePerson(withID: person.id) // Then delete person
    }
    
    // MARK: - Social Media Helpers
    
    func openSocialMedia(urlString: String?) {
        guard let urlString = urlString, 
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Upcoming Events
    
    struct UpcomingEvent: Identifiable {
        let id: UUID // Person ID
        let personName: String // Renamed from contactName
        let eventType: String
        let date: Date
        let daysAway: Int
    }
    
    var upcomingEvents: [UpcomingEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        let futureLimit = Calendar.current.date(byAdding: .day, value: 30, to: today)!
        var events: [UpcomingEvent] = []
        
        for person in personStore.people { // Use personStore.people
            // Check Birthday
            if let birthday = person.birthday {
                if let nextBirthday = Calendar.current.nextDate(after: today, matching: Calendar.current.dateComponents([.month, .day], from: birthday), matchingPolicy: .nextTimePreservingSmallerComponents),
                   nextBirthday <= futureLimit {
                    let daysAway = Calendar.current.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
                    events.append(UpcomingEvent(id: person.id, personName: person.name, eventType: "Birthday", date: nextBirthday, daysAway: daysAway))
                }
            }
            
            // Check Anniversary
            if let anniversary = person.anniversary {
                 if let nextAnniversary = Calendar.current.nextDate(after: today, matching: Calendar.current.dateComponents([.month, .day], from: anniversary), matchingPolicy: .nextTimePreservingSmallerComponents),
                   nextAnniversary <= futureLimit {
                    let daysAway = Calendar.current.dateComponents([.day], from: today, to: nextAnniversary).day ?? 0
                    events.append(UpcomingEvent(id: person.id, personName: person.name, eventType: "Anniversary", date: nextAnniversary, daysAway: daysAway))
                }
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    // MARK: - Spontaneous Suggestion
    
    func generateSpontaneousSuggestion() {
        let eligiblePeople = personStore.people.filter { person in
            // Optionally: exclude people already in the main suggestion list?
            // !suggestedPeopleToReachOutTo.contains(where: { $0.id == person.id })
            true // For now, consider everyone
        }
        
        spontaneousSuggestion = eligiblePeople.randomElement()
    }
    
    // MARK: - Timeline Data
    
    // Get all timeline entries for unified timeline display
    func getAllTimelineEntries() -> [TimelineEntry] {
        var entries: [TimelineEntry] = []
        
        // 1. Add birthdays
        for person in personStore.people {
            if let birthday = person.birthday {
                // Get next birthday
                let today = Calendar.current.startOfDay(for: Date())
                if let nextBirthday = Calendar.current.nextDate(
                    after: today,
                    matching: Calendar.current.dateComponents([.month, .day], from: birthday),
                    matchingPolicy: .nextTimePreservingSmallerComponents) {
                    
                    let age = Calendar.current.dateComponents([.year], from: birthday, to: nextBirthday).year ?? 0
                    
                    entries.append(TimelineEntry(
                        title: "\(person.name)'s Birthday",
                        subtitle: "Turning \(age)",
                        date: nextBirthday,
                        iconName: "gift",
                        iconColor: .pink,
                        entryType: .birthday,
                        personId: person.id,
                        action: { /* Action now handled by NavigationLink */ }
                    ))
                }
            }
            
            // 2. Add anniversaries
            if let anniversary = person.anniversary {
                // Get next anniversary
                let today = Calendar.current.startOfDay(for: Date())
                if let nextAnniversary = Calendar.current.nextDate(
                    after: today,
                    matching: Calendar.current.dateComponents([.month, .day], from: anniversary),
                    matchingPolicy: .nextTimePreservingSmallerComponents)
                {
                    // Calculate years
                    let years = Calendar.current.dateComponents([.year], from: anniversary, to: nextAnniversary).year ?? 0
                    
                    // Create TimelineEntry for anniversary
                    entries.append(TimelineEntry(
                        title: "\(person.name)'s Anniversary",
                        subtitle: "\(years) years",
                        date: nextAnniversary,
                        iconName: "sparkles", // Use appropriate icon
                        iconColor: .purple,  // Use appropriate color
                        entryType: .anniversary,
                        personId: person.id,
                        action: { /* Action handled by NavigationLink */ }
                    ))
                }
            }
            
            // 3. Add Life Events
            for event in person.lifeEvents {
                entries.append(TimelineEntry(
                    title: event.title,
                    subtitle: "\(person.name) - \(event.type.rawValue)",
                    date: event.date,
                    iconName: event.type.iconName, // Use icon from LifeEvent.EventType
                    iconColor: event.type.color,     // Use color from LifeEvent.EventType
                    entryType: .lifeEvent,
                    personId: person.id,
                    action: { /* Action handled by NavigationLink */ }
                ))
            }
        }
        
        // 4. Add suggested interactions (Keep existing logic)
        for person in suggestedPeopleToReachOutTo {
            // Define a date formatter locally or reuse if available globally
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let lastContactString = person.lastContactDate != nil ? dateFormatter.string(from: person.lastContactDate!) : "Never"
            let timeSince = lastContactString // Use formatted string
            entries.append(TimelineEntry(
                title: "Connect with \(person.name)",
                subtitle: "Last interaction: \(timeSince)",
                date: Date(), // Suggestion date is today
                iconName: "person.crop.circle.badge.exclamationmark",
                iconColor: .orange,
                entryType: .suggestedInteraction,
                personId: person.id,
                action: { /* Action handled by NavigationLink */ }
            ))
        }
        
        // 5. Add connection goals (Adapt to ConnectionGoal properties)
        for goal in connectionGoals {
            // Calculate the next deadline based on timeframe and start date
            let today = Calendar.current.startOfDay(for: Date())
            var nextDeadline = goal.startDate // Start with goal start date
            
            let timeframe = goal.timeframe 
            // Keep adding the timeframe interval until the date is in the future
            while nextDeadline < today {
                nextDeadline = timeframe.nextEndDate(from: nextDeadline) 
                // Safety break in case nextEndDate doesn't advance (shouldn't happen with current enum)
                if nextDeadline <= today { 
                   // If timeframe logic somehow doesn't advance, force break
                   // to prevent potential infinite loop, maybe log an error.
                   nextDeadline = Date.distantFuture
                   break 
                } 
             }
             
            // Use the first related person's ID for the timeline entry, if available
            let relatedPersonID = goal.relatedPersonIds.first
            
            entries.append(TimelineEntry(
                title: goal.title,
                subtitle: "Goal Deadline", // Generic subtitle
                date: nextDeadline, // Use calculated next deadline
                iconName: "target",
                iconColor: .purple,
                entryType: .connectionGoal,
                personId: relatedPersonID, // Use the assumed personID property
                action: { /* Action handled by NavigationLink (Placeholder) */ }
            ))
        }
        
        // Sort all entries by date
        return entries.sorted { $0.date < $1.date }
    }
    
    // Get recent interactions with mood data
    func getRecentInteractions(limit: Int = 30) -> [InteractionWithMood] {
        var recentInteractions: [InteractionWithMood] = []
        
        for person in personStore.people {
            for interaction in person.interactionHistory {
                let mood = person.interactionMoods[interaction.id]
                recentInteractions.append(
                    InteractionWithMood(
                        interaction: interaction,
                        personId: person.id,
                        mood: mood
                    )
                )
            }
        }
        
        // Sort by date, most recent first
        return recentInteractions
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Life Events Management
    
    func addLifeEvent(for personId: UUID, event: LifeEvent) {
        if var person = personStore.people.first(where: { $0.id == personId }) {
            person.lifeEvents.append(event)
            personStore.updatePerson(person)
        }
    }
    
    func updateLifeEvent(for personId: UUID, event: LifeEvent) {
        if var person = personStore.people.first(where: { $0.id == personId }) {
            if let index = person.lifeEvents.firstIndex(where: { $0.id == event.id }) {
                person.lifeEvents[index] = event
                personStore.updatePerson(person)
            }
        }
    }
    
    func deleteLifeEvent(for personId: UUID, eventId: UUID) {
        if var person = personStore.people.first(where: { $0.id == personId }) {
            person.lifeEvents.removeAll(where: { $0.id == eventId })
            personStore.updatePerson(person)
        }
    }
    
    // MARK: - Mood Tracking
    
    func recordInteractionWithMood(for personId: UUID, type: Person.InteractionType, note: String? = nil, mood: Mood? = nil) {
        if var person = personStore.people.first(where: { $0.id == personId }) {
            let interaction = InteractionLog(type: type, note: note)
            person.interactionHistory.append(interaction)
            
            if let mood = mood {
                person.interactionMoods[interaction.id] = mood
            }
            
            person.lastContactDate = Date()
            
            // Update stats
            switch type {
            case .meeting: person.meetingCount += 1
            case .call: person.callCount += 1
            case .message: person.messageCount += 1
            }
            
            personStore.updatePerson(person)
            
            // Check for matching connection goals
            updateConnectionGoalsForInteraction(interaction, person: person)
        }
    }
    
    // MARK: - Connection Goals
    
    func addConnectionGoal(_ goal: ConnectionGoal) {
        connectionGoals.append(goal)
        saveConnectionGoals()
    }
    
    func updateConnectionGoal(_ goal: ConnectionGoal) {
        if let index = connectionGoals.firstIndex(where: { $0.id == goal.id }) {
            connectionGoals[index] = goal
            saveConnectionGoals()
        }
    }
    
    func deleteConnectionGoal(id: UUID) {
        connectionGoals.removeAll(where: { $0.id == id })
        saveConnectionGoals()
    }
    
    private func updateConnectionGoalsForInteraction(_ interaction: InteractionLog, person: Person) {
        var goalsUpdated = false
        
        for i in 0..<connectionGoals.count {
            if connectionGoals[i].matchesInteraction(interaction, person: person) &&
               !connectionGoals[i].completedInteractions.contains(interaction.id) {
                // Add this interaction to the goal's completed interactions
                connectionGoals[i].completedInteractions.append(interaction.id)
                goalsUpdated = true
            }
        }
        
        if goalsUpdated {
            saveConnectionGoals()
        }
    }
    
    func resetCompletedGoals() {
        for i in 0..<connectionGoals.count {
            if connectionGoals[i].progressPercentage >= 1.0 {
                connectionGoals[i].resetForNewPeriod()
            }
        }
        saveConnectionGoals()
    }
    
    private func saveConnectionGoals() {
        if let encoded = try? JSONEncoder().encode(connectionGoals) {
            UserDefaults.standard.set(encoded, forKey: connectionGoalsKey)
        }
    }
    
    private func loadConnectionGoals() -> [ConnectionGoal] {
        if let data = UserDefaults.standard.data(forKey: connectionGoalsKey),
           let decoded = try? JSONDecoder().decode([ConnectionGoal].self, from: data) {
            return decoded
        }
        return []
    }
} 