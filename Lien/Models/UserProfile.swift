import Foundation

struct UserProfile: Codable {
    var name: String
    var dateOfBirth: Date
    var lifeExpectancy: Int = 80
    var profileImageData: Data?
    
    // The user can customize how many times they want to meet with each contact type
    var meetingGoals: [Person.RelationshipType: Int] = [
        .family: 52,        // weekly
        .closeFriend: 26,   // biweekly
        .friend: 12,        // monthly
        .acquaintance: 4,   // quarterly
        .colleague: 12,     // monthly
        .other: 4          // quarterly
    ]
    
    init(name: String = "", dateOfBirth: Date = Date()) {
        self.name = name
        self.dateOfBirth = dateOfBirth
    }
    
    // MARK: - Philosophical Time Calculations
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    
    var yearsRemaining: Int {
        max(0, lifeExpectancy - age)
    }
    
    var monthsRemaining: Int {
        yearsRemaining * 12
    }
    
    var weeksRemaining: Int {
        yearsRemaining * 52
    }
    
    var daysRemaining: Int {
        yearsRemaining * 365
    }
    
    func meetings(for person: Person) -> Int {
        guard let relationship = meetingGoals[person.relationshipType] else {
            return 0
        }
        return yearsRemaining * relationship
    }
    
    // MARK: - Persistence
    
    static func save(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "user-profile")
        }
    }
    
    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: "user-profile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        
        return profile
    }
} 