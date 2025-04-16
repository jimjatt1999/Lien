import Foundation
import Combine

class LinkStore: ObservableObject {
    @Published var links: [RelationshipLink] = []
    private let saveKey = "saved-relationship-links"

    init() {
        loadLinks()
    }

    // MARK: - Link Management

    func addLink(person1ID: UUID, person2ID: UUID, label: String) {
        // Ensure we don't add duplicate links (ignoring label for duplication check)
        let (id1, id2) = RelationshipLink.orderedIDs(person1ID, person2ID)
        if !linkExists(person1ID: id1, person2ID: id2) {
            let newLink = RelationshipLink(person1ID: id1, person2ID: id2, label: label)
            links.append(newLink)
            saveLinks()
        }
    }

    func removeLink(id: UUID) {
        links.removeAll { $0.id == id }
        saveLinks()
    }
    
    func removeLinks(involving personID: UUID) {
        links.removeAll { $0.person1ID == personID || $0.person2ID == personID }
        saveLinks()
    }

    func updateLinkLabel(id: UUID, newLabel: String) {
        if let index = links.firstIndex(where: { $0.id == id }) {
            links[index].label = newLabel
            saveLinks()
        }
    }
    
    func getLinks(for personID: UUID) -> [RelationshipLink] {
        links.filter { $0.person1ID == personID || $0.person2ID == personID }
    }
    
    func linkExists(person1ID: UUID, person2ID: UUID) -> Bool {
        let (id1, id2) = RelationshipLink.orderedIDs(person1ID, person2ID)
        return links.contains { $0.person1ID == id1 && $0.person2ID == id2 }
    }
    
    func findLink(person1ID: UUID, person2ID: UUID) -> RelationshipLink? {
         let (id1, id2) = RelationshipLink.orderedIDs(person1ID, person2ID)
         return links.first { $0.person1ID == id1 && $0.person2ID == id2 }
    }

    // MARK: - Persistence

    private func saveLinks() {
        if let encoded = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadLinks() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([RelationshipLink].self, from: data) else {
            links = []
            return
        }
        links = decoded
    }
} 