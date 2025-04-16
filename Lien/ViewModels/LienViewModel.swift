import Foundation
import SwiftUI
import Combine

class LienViewModel: ObservableObject {
    @Published var personStore = PersonStore()
    @Published var linkStore = LinkStore()
    @Published var userProfile: UserProfile
    @Published var isOnboarded: Bool
    
    // Needed for filtering in PeopleListView
    @Published var activeTagFilter: String? = nil
    @Published var searchText: String = ""
    
    private let isOnboardedKey = "is-onboarded"
    
    init() {
        self.userProfile = UserProfile.load()
        self.isOnboarded = UserDefaults.standard.bool(forKey: isOnboardedKey)
        
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
} 