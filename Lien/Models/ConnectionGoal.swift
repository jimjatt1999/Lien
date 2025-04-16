import Foundation
import SwiftUI

struct ConnectionGoal: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var description: String?
    var targetType: TargetType
    var targetValue: Int
    var timeframe: Timeframe
    var startDate: Date
    var relatedPersonIds: [UUID] = [] // Optional - specific people this goal relates to
    var tags: [String] = [] // Optional - tags this goal relates to
    var relationshipType: Person.RelationshipType? // Optional - specific relationship type
    var completedInteractions: [UUID] = [] // IDs of interactions that count toward this goal
    
    enum TargetType: String, Codable, CaseIterable {
        case meetings = "In-person Meetings"
        case calls = "Phone Calls"
        case messages = "Messages"
        case anyInteraction = "Any Interaction"
        
        var iconName: String {
            switch self {
            case .meetings: return "person.2.fill"
            case .calls: return "phone.fill"
            case .messages: return "message.fill"
            case .anyInteraction: return "person.wave.2.fill"
            }
        }
    }
    
    enum Timeframe: String, Codable, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        
        var intervalDays: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .quarterly: return 90
            case .yearly: return 365
            }
        }
        
        func nextEndDate(from startDate: Date) -> Date {
            let calendar = Calendar.current
            switch self {
            case .weekly:
                return calendar.date(byAdding: .day, value: 7, to: startDate)!
            case .monthly:
                return calendar.date(byAdding: .month, value: 1, to: startDate)!
            case .quarterly:
                return calendar.date(byAdding: .month, value: 3, to: startDate)!
            case .yearly:
                return calendar.date(byAdding: .year, value: 1, to: startDate)!
            }
        }
    }
    
    // Current goal progress percentage (0.0 - 1.0)
    var progressPercentage: Double {
        if targetValue <= 0 { return 0.0 }
        let progress = Double(completedInteractions.count) / Double(targetValue)
        return min(1.0, progress) // Cap at 100%
    }
    
    // Days remaining in current timeframe
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate the end of the current period
        var currentPeriodStart = startDate
        var currentPeriodEnd = timeframe.nextEndDate(from: startDate)
        
        // Find the current period we're in
        while currentPeriodEnd < today {
            currentPeriodStart = currentPeriodEnd
            currentPeriodEnd = timeframe.nextEndDate(from: currentPeriodStart)
        }
        
        // Calculate days remaining
        guard let days = calendar.dateComponents([.day], from: today, to: currentPeriodEnd).day else {
            return 0
        }
        return max(0, days)
    }
    
    // Check if the goal is on track
    var isOnTrack: Bool {
        // If no days left, check if completed
        if daysRemaining <= 0 {
            return completedInteractions.count >= targetValue
        }
        
        // Calculate expected progress
        let totalDays = timeframe.intervalDays
        let daysElapsed = totalDays - daysRemaining
        let expectedCompletion = Double(targetValue) * (Double(daysElapsed) / Double(totalDays))
        
        // Compare actual to expected
        return Double(completedInteractions.count) >= expectedCompletion
    }
    
    // Calculated status indicator
    var status: GoalStatus {
        if progressPercentage >= 1.0 {
            return .completed
        } else if isOnTrack {
            return .onTrack
        } else if daysRemaining <= 7 && progressPercentage < 0.5 {
            return .atRisk
        } else {
            return .inProgress
        }
    }
    
    // Goal status enum
    enum GoalStatus {
        case onTrack, inProgress, atRisk, completed
        
        var description: String {
            switch self {
            case .onTrack: return "On Track"
            case .inProgress: return "In Progress"
            case .atRisk: return "At Risk"
            case .completed: return "Completed"
            }
        }
        
        var color: Color {
            switch self {
            case .onTrack: return .green
            case .inProgress: return .blue
            case .atRisk: return .orange
            case .completed: return .purple
            }
        }
    }
    
    // Check if an interaction matches this goal's criteria
    func matchesInteraction(_ interaction: InteractionLog, person: Person) -> Bool {
        // Check if the interaction type matches the goal's target type
        let typeMatches: Bool
        switch targetType {
        case .meetings:
            typeMatches = interaction.type == .meeting
        case .calls:
            typeMatches = interaction.type == .call
        case .messages:
            typeMatches = interaction.type == .message
        case .anyInteraction:
            typeMatches = true
        }
        
        // If specific people are targeted, check if this person is included
        let personMatches = relatedPersonIds.isEmpty || relatedPersonIds.contains(person.id)
        
        // If specific relationship type is targeted, check if this person matches
        let relationshipMatches = relationshipType == nil || person.relationshipType == relationshipType
        
        // If tags are specified, check if this person has any matching tags
        let tagMatches = tags.isEmpty || !Set(tags).isDisjoint(with: Set(person.tags))
        
        return typeMatches && personMatches && relationshipMatches && tagMatches
    }
    
    // Reset goal for a new timeframe period
    mutating func resetForNewPeriod() {
        completedInteractions = []
        startDate = Date() // Reset to today
    }
}

// Helper extension to get all goals matching specific criteria
extension Array where Element == ConnectionGoal {
    func forPerson(_ person: Person) -> [ConnectionGoal] {
        return self.filter { goal in
            return goal.relatedPersonIds.isEmpty || 
                goal.relatedPersonIds.contains(person.id)
        }
    }
    
    func forRelationshipType(_ type: Person.RelationshipType) -> [ConnectionGoal] {
        return self.filter { goal in
            return goal.relationshipType == nil ||
                goal.relationshipType == type
        }
    }
    
    func matchingTags(_ tags: [String]) -> [ConnectionGoal] {
        return self.filter { goal in
            return goal.tags.isEmpty || 
                !Set(goal.tags).isDisjoint(with: Set(tags))
        }
    }
    
    func activeGoals() -> [ConnectionGoal] {
        return self.filter { $0.progressPercentage < 1.0 }
    }
} 