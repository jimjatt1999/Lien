import Foundation
import SwiftUI

struct Contact: Identifiable, Codable {
    var id = UUID()
    var name: String
    var age: Int?
    var birthday: Date?
    var image: Data?
    
    // Contact information
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
    
    // Stats
    var meetingCount: Int = 0
    var callCount: Int = 0
    var messageCount: Int = 0
    
    var lifeExpectancy: Int = 80 // Default life expectancy
    
    enum RelationshipType: String, Codable, CaseIterable {
        case family = "Family"
        case closeFriend = "Close Friend"
        case friend = "Friend"
        case acquaintance = "Acquaintance"
        case colleague = "Colleague"
        case other = "Other"
    }
    
    enum MeetFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case custom = "Custom"
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
    
    var daysSinceLastContact: Int? {
        guard let lastContact = lastContactDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day
    }
    
    var isContactDue: Bool {
        guard let days = daysSinceLastContact else { return true }
        
        switch meetFrequency {
        case .daily: return days >= 1
        case .weekly: return days >= 7
        case .biweekly: return days >= 14
        case .monthly: return days >= 30
        case .quarterly: return days >= 90
        case .yearly: return days >= 365
        case .custom: return false // Handle custom frequency elsewhere
        }
    }
} 