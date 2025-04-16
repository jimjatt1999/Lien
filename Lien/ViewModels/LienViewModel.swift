import Foundation
import SwiftUI
import Combine

class LienViewModel: ObservableObject {
    @Published var contactStore = ContactStore()
    @Published var userProfile: UserProfile
    @Published var isOnboarded: Bool
    
    private let isOnboardedKey = "is-onboarded"
    
    init() {
        self.userProfile = UserProfile.load()
        self.isOnboarded = UserDefaults.standard.bool(forKey: isOnboardedKey)
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile() {
        UserProfile.save(userProfile)
    }
    
    func completeOnboarding() {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: isOnboardedKey)
    }
    
    // MARK: - Contact Management
    
    var dueTodayContacts: [Contact] {
        contactStore.contactsDueForInteraction
    }
    
    var contactGroups: [(String, [Contact])] {
        let groups = Dictionary(grouping: contactStore.contacts) { contact in
            contact.relationshipType.rawValue
        }
        
        return groups.map { (key, value) in
            (key, value.sorted { $0.name < $1.name })
        }.sorted { $0.0 < $1.0 }
    }
    
    func contactsWithSameTag(_ tag: String) -> [Contact] {
        contactStore.contacts.filter { $0.tags.contains(tag) }
    }
    
    // Philosophical calculations for each contact
    func weeksRemaining(with contact: Contact) -> Int {
        let yearsLeft = min(userProfile.yearsRemaining, contact.lifeExpectancy - (contact.age ?? 30))
        return yearsLeft * 52
    }
    
    func meetingsRemaining(with contact: Contact) -> Int {
        let years = min(userProfile.yearsRemaining, contact.lifeExpectancy - (contact.age ?? 30))
        
        let frequencyPerYear: Int
        switch contact.meetFrequency {
        case .daily: frequencyPerYear = 365
        case .weekly: frequencyPerYear = 52
        case .biweekly: frequencyPerYear = 26
        case .monthly: frequencyPerYear = 12
        case .quarterly: frequencyPerYear = 4
        case .yearly: frequencyPerYear = 1
        case .custom: frequencyPerYear = 12 // Default to monthly
        }
        
        return years * frequencyPerYear
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
} 