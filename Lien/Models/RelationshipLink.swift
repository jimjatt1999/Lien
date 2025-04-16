import Foundation

struct RelationshipLink: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var person1ID: UUID
    var person2ID: UUID
    var label: String // e.g., "Family", "Colleagues", "Friends via Alice"
    
    // Helper to ensure consistent ordering for storage/lookup if needed
    static func orderedIDs(_ id1: UUID, _ id2: UUID) -> (UUID, UUID) {
        return id1.uuidString < id2.uuidString ? (id1, id2) : (id2, id1)
    }
} 