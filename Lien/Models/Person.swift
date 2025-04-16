import Foundation
import SwiftUI

// Renamed from InteractionLog
struct InteractionLog: Identifiable, Codable, Equatable {
    let id = UUID()
    var date: Date = Date()
    var type: Person.InteractionType // Updated reference
    var note: String?
}

// Renamed from Contact
struct Person: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    // Removed age: Int? - Handled by birthday
    var birthday: Date?
    var anniversary: Date?
    var image: Data?
    
    // Contact information -> Personal Information
    var phone: String?
    var email: String?
    
    // Social media links
    var instagram: String?
    var whatsapp: String?
    var facebook: String?
    var twitter: String?
    var linkedin: String?
    var otherSocialLinks: [String: String] = [:]
    
    // Relationship information
    var relationshipType: RelationshipType
    var meetFrequency: MeetFrequency
    var lastContactDate: Date?
    var notes: String = ""
    var tags: [String] = []
    var interactionHistory: [InteractionLog] = []
    var isCorePerson: Bool = false // Added for Core People feature
    
    // New properties for enhanced features
    var lifeEvents: [LifeEvent] = []
    var interactionMoods: [UUID: Mood] = [:] // Maps interaction IDs to moods
    
    // Stats (Can be derived from history later if needed)
    var meetingCount: Int = 0
    var callCount: Int = 0
    var messageCount: Int = 0
    
    var lifeExpectancy: Int = 80 // Default life expectancy - maybe move to UserProfile?
    
    // Renamed from Contact.InteractionType, added Codable conformance directly
    enum InteractionType: String, Codable, CaseIterable {
        case meeting = "Meeting"
        case call = "Call"
        case message = "Message"
    }
    
    enum RelationshipType: String, Codable, CaseIterable {
        case family = "Family"
        case closeFriend = "Close Friend"
        case friend = "Friend"
        case acquaintance = "Acquaintance"
        case colleague = "Colleague"
        case other = "Other"
    }
    
    // Modified MeetFrequency with associated value for custom
    enum MeetFrequency: Equatable, Hashable {
        case daily
        case weekly
        case biweekly
        case monthly
        case quarterly
        case yearly
        case custom(days: Int)
        
        // Helper for display name
        var rawValue: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .biweekly: return "Bi-Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            case .custom(let days): return "Every \(days) days"
            }
        }
        
        // All selectable cases (excluding raw custom)
        static var allCasesForPicker: [MeetFrequency] {
            return [.daily, .weekly, .biweekly, .monthly, .quarterly, .yearly, .custom(days: 7)] // Default custom to 7 days for picker init
        }
        
        // Helper to get interval days
        var intervalDays: Int? {
             switch self {
             case .daily: return 1
             case .weekly: return 7
             case .biweekly: return 14
             case .monthly: return 30 // Approximation
             case .quarterly: return 90 // Approximation
             case .yearly: return 365 // Approximation
             case .custom(let days): return days > 0 ? days : nil // Ensure positive days
             }
         }
    }
    
    // Helper computed properties
    var initials: String {
        name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first?.uppercased() }
            .joined()
    }
    
    var displayImage: Image? {
        if let imageData = image, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    var age: Int? { // Calculate age from birthday if available
        guard let bd = birthday else { return nil }
        return Calendar.current.dateComponents([.year], from: bd, to: Date()).year
    }
    
    var daysSinceLastContact: Int? {
        guard let lastContact = lastContactDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day
    }
    
    var isDue: Bool { // Renamed from isContactDue
        guard let daysSince = daysSinceLastContact else { return true } // Assume due if never contacted
        guard let interval = meetFrequency.intervalDays else { return false } // Cannot determine if interval is nil/invalid
        
        return daysSince >= interval
    }
    
    enum RelationshipStatus {
        case recent, approaching, due, unknown
        
        var color: Color {
            switch self {
            case .recent: return .green
            case .approaching: return .yellow
            case .due: return .red
            case .unknown: return .gray
            }
        }
        
        var description: String {
            switch self {
            case .recent: return "Recent"
            case .approaching: return "Approaching"
            case .due: return "Due"
            case .unknown: return "Unknown"
            }
        }
    }
    
    var relationshipStatus: RelationshipStatus {
        guard let lastContact = lastContactDate, 
              let daysSince = daysSinceLastContact, 
              let intervalDays = meetFrequency.intervalDays else { 
            return .unknown 
        }
        
        let ratio = Double(daysSince) / Double(intervalDays)
        
        if ratio >= 1.0 {
            return .due
        } else if ratio >= 0.6 { // Use ratio for approaching
            return .approaching
        } else {
            return .recent
        }
    }
    
    // Health Status Enum
    enum RelationshipHealthStatus {
        case thriving, stable, needsAttention, unknown
        
        var description: String {
            switch self {
            case .thriving: return "Thriving"
            case .stable: return "Stable"
            case .needsAttention: return "Needs Attention"
            case .unknown: return "Unknown"
            }
        }
        
        var color: Color {
            switch self {
            case .thriving: return .green
            case .stable: return .yellow
            case .needsAttention: return .red
            case .unknown: return .gray
            }
        }
    }

    // Computed property for Health Status
    var relationshipHealth: RelationshipHealthStatus {
        switch self.relationshipStatus { // Based directly on relationshipStatus for now
        case .recent: return .thriving
        case .approaching: return .stable
        case .due: return .needsAttention
        case .unknown: return .unknown
        }
    }
    
    // Added for Pulse Score
    var pulseScore: Double {
        guard let daysSince = daysSinceLastContact else { return 0.5 } // Unknown/never contacted = neutral pulse
        
        // Use intervalDays helper
        guard let desiredDays = meetFrequency.intervalDays, desiredDays > 0 else { 
            return 0.5 // Cannot calculate if interval is invalid/zero, return neutral
        }
        
        let ratio = Double(daysSince) / Double(desiredDays)
        // Score decreases as ratio increases (more time passed than desired)
        // Score is 1.0 if days = 0, decreases towards 0 as days approaches/exceeds desiredDays.
        // Clamp ensures score stays between 0.0 and 1.0.
        let score = 1.0 - ratio
        return max(0.0, min(1.0, score)) // Clamp result between 0.0 and 1.0
    }
}

// Custom Codable conformance for MeetFrequency
extension Person.MeetFrequency: Codable {
    enum CodingKeys: String, CodingKey {
        case base, days
    }
    
    enum Base: String, Codable {
        case daily, weekly, biweekly, monthly, quarterly, yearly, custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .daily: try container.encode(Base.daily, forKey: .base)
        case .weekly: try container.encode(Base.weekly, forKey: .base)
        case .biweekly: try container.encode(Base.biweekly, forKey: .base)
        case .monthly: try container.encode(Base.monthly, forKey: .base)
        case .quarterly: try container.encode(Base.quarterly, forKey: .base)
        case .yearly: try container.encode(Base.yearly, forKey: .base)
        case .custom(let days): 
            try container.encode(Base.custom, forKey: .base)
            try container.encode(days, forKey: .days)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        
        switch base {
        case .daily: self = .daily
        case .weekly: self = .weekly
        case .biweekly: self = .biweekly
        case .monthly: self = .monthly
        case .quarterly: self = .quarterly
        case .yearly: self = .yearly
        case .custom: 
            let days = try container.decodeIfPresent(Int.self, forKey: .days) ?? 7 // Default to 7 if missing
            self = .custom(days: days)
        }
    }
}

// Extension for calculating meetings per year
extension Person.MeetFrequency {
    func meetingsPerYear() -> Double {
        guard let days = self.intervalDays, days > 0 else { return 0 } // Use intervalDays helper
        return 365.0 / Double(days)
    }
}

// REMOVED Extension for InteractionType Codable conformance
/*
extension Person.InteractionType: Codable {}
*/ 