import Foundation
import SwiftUI

struct LifeEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var description: String?
    var type: EventType
    var reminderFrequency: ReminderFrequency? // Optional reminder
    
    enum EventType: String, Codable, CaseIterable {
        case newJob = "New Job"
        case graduation = "Graduation"
        case moved = "Moved"
        case relationshipStart = "New Relationship"
        case relationshipEnd = "Relationship Ended"
        case newChild = "New Child"
        case majorAchievement = "Achievement"
        case healthEvent = "Health Event"
        case other = "Other"
        
        var iconName: String {
            switch self {
            case .newJob: return "briefcase"
            case .graduation: return "graduationcap"
            case .moved: return "house"
            case .relationshipStart: return "heart"
            case .relationshipEnd: return "heart.slash"
            case .newChild: return "figure.and.child"
            case .majorAchievement: return "trophy"
            case .healthEvent: return "heart.text.square"
            case .other: return "star"
            }
        }
        
        var color: Color {
            switch self {
            case .newJob, .graduation, .majorAchievement: return .blue
            case .moved: return .green
            case .relationshipStart: return .pink
            case .relationshipEnd: return .purple
            case .newChild: return .orange
            case .healthEvent: return .red
            case .other: return .gray
            }
        }
    }
    
    enum ReminderFrequency: String, Codable, CaseIterable {
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case yearly = "Yearly"
        case none = "No Reminder"
        
        var intervalDays: Int? {
            switch self {
            case .oneWeek: return 7
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .yearly: return 365
            case .none: return nil
            }
        }
    }
    
    // Computed property to check if a reminder is due
    var isReminderDue: Bool {
        guard let reminderFreq = reminderFrequency, reminderFreq != .none else {
            return false // No reminder set
        }
        
        guard let intervalDays = reminderFreq.intervalDays else {
            return false
        }
        
        // Check if today's date is a multiple of the interval from the event date
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDate = calendar.startOfDay(for: date)
        
        guard let daysSinceEvent = calendar.dateComponents([.day], from: eventDate, to: today).day else {
            return false
        }
        
        // Check if we've passed a reminder interval
        return daysSinceEvent > 0 && daysSinceEvent % intervalDays == 0
    }
    
    // Calculate the next reminder date
    var nextReminderDate: Date? {
        guard let reminderFreq = reminderFrequency, reminderFreq != .none else {
            return nil // No reminder set
        }
        
        guard let intervalDays = reminderFreq.intervalDays else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDate = calendar.startOfDay(for: date)
        
        guard let daysSinceEvent = calendar.dateComponents([.day], from: eventDate, to: today).day else {
            return nil
        }
        
        // Find next reminder date after today
        let nextMultiple = ((daysSinceEvent / intervalDays) + 1) * intervalDays
        return calendar.date(byAdding: .day, value: nextMultiple - daysSinceEvent, to: today)
    }
}

// Helper extension for working with LifeEvents
extension Array where Element == LifeEvent {
    // Get upcoming reminder events
    func upcomingReminders(within days: Int = 30) -> [LifeEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let future = calendar.date(byAdding: .day, value: days, to: today)!
        
        return self.filter { event in
            guard let nextReminder = event.nextReminderDate else { return false }
            return nextReminder >= today && nextReminder <= future
        }.sorted { $0.nextReminderDate! < $1.nextReminderDate! }
    }
    
    // Get recent life events
    func recent(within days: Int = 90) -> [LifeEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let past = calendar.date(byAdding: .day, value: -days, to: today)!
        
        return self.filter { $0.date >= past && $0.date <= today }
            .sorted { $0.date > $1.date }
    }
} 