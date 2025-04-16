import Foundation

// Enum defining filter categories for the PeopleListView
enum PeopleListFilter: CaseIterable, Identifiable {
    case all, core, other, suggested
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .core: return "Core"
        case .other: return "Other"
        case .suggested: return "Suggested"
        }
    }
} 