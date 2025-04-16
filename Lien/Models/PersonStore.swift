import Foundation
import Combine

// Renamed from ContactStore
class PersonStore: ObservableObject {
    @Published var people: [Person] = [] // Renamed from contacts
    @Published var searchText: String = ""
    private let saveKey = "saved-people" // Updated save key
    
    // Renamed from filteredContacts
    var filteredPeople: [Person] { // Basic search filter, more complex filtering in ViewModel
        if searchText.isEmpty {
            return people
        } else {
            return people.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText) ||
                person.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // Renamed from contactsDueForInteraction
    var peopleDueForInteraction: [Person] {
        people.filter { $0.isDue } // Use the renamed property 'isDue'
    }
    
    init() {
        loadPeople() // Renamed method
    }
    
    // Renamed from addContact
    func addPerson(_ person: Person) {
        people.append(person)
        savePeople() // Renamed method
    }
    
    // Renamed from updateContact
    func updatePerson(_ person: Person) {
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            savePeople()
        }
    }
    
    // Renamed from deleteContact
    func deletePerson(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
        savePeople()
    }
    
    // Renamed from deleteContact
    func deletePerson(withID id: UUID) {
        if let index = people.firstIndex(where: { $0.id == id }) {
            people.remove(at: index)
            savePeople()
        }
    }
    
    // Renamed from recordContact
    func recordInteraction(for personId: UUID, type: Person.InteractionType, note: String? = nil) {
        if let index = people.firstIndex(where: { $0.id == personId }) {
            var person = people[index]
            person.lastContactDate = Date()
            
            let logEntry = InteractionLog(type: type, note: note)
            person.interactionHistory.insert(logEntry, at: 0)
            
            // Update stats (consider removing later)
            switch type {
            case .meeting: person.meetingCount += 1
            case .call: person.callCount += 1
            case .message: person.messageCount += 1
            }
            
            people[index] = person
            savePeople()
        }
    }
    
    // MARK: - Persistence
    
    // Renamed from saveContacts
    private func savePeople() {
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // Renamed from loadContacts
    private func loadPeople() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else {
            people = [] // Start fresh if loading fails
            return
        }
        
        people = decoded
    }
} 