import Foundation
import Combine

class ContactStore: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var searchText: String = ""
    private let saveKey = "saved-contacts"
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var contactsDueForInteraction: [Contact] {
        contacts.filter { $0.isContactDue }
    }
    
    init() {
        loadContacts()
    }
    
    func addContact(_ contact: Contact) {
        contacts.append(contact)
        saveContacts()
    }
    
    func updateContact(_ contact: Contact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            saveContacts()
        }
    }
    
    func deleteContact(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
        saveContacts()
    }
    
    func deleteContact(withID id: UUID) {
        if let index = contacts.firstIndex(where: { $0.id == id }) {
            contacts.remove(at: index)
            saveContacts()
        }
    }
    
    func recordContact(for id: UUID, type: ContactInteractionType) {
        if let index = contacts.firstIndex(where: { $0.id == id }) {
            var contact = contacts[index]
            contact.lastContactDate = Date()
            
            switch type {
            case .meeting:
                contact.meetingCount += 1
            case .call:
                contact.callCount += 1
            case .message:
                contact.messageCount += 1
            }
            
            contacts[index] = contact
            saveContacts()
        }
    }
    
    enum ContactInteractionType {
        case meeting, call, message
    }
    
    // MARK: - Persistence
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadContacts() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Contact].self, from: data) else {
            // Load sample data for first-time users
            contacts = []
            return
        }
        
        contacts = decoded
    }
} 