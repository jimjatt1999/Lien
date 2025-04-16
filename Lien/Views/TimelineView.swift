import SwiftUI

struct TimelineView: View {
    @ObservedObject var viewModel: LienViewModel
    
    // State for adding life events using a unified flow
    enum AddLifeEventFlow: Identifiable {
        case selectPerson
        case editEvent(Person)
        
        var id: String {
            switch self {
            case .selectPerson:
                return "selectPerson"
            case .editEvent(let person):
                return "editEvent-\(person.id.uuidString)"
            }
        }
    }
    @State private var addLifeEventFlow: AddLifeEventFlow? = nil
    
    // Group the timeline entries by date section
    private var groupedTimelineEntries: [DateSection: [TimelineEntry]] {
        let allEntries = viewModel.getAllTimelineEntries()
        var grouped: [DateSection: [TimelineEntry]] = [:]
        
        // Categorize entries into today, tomorrow, this week, this month, later
        for entry in allEntries {
            let section = entry.dateSection
            if grouped[section] == nil {
                grouped[section] = []
            }
            grouped[section]?.append(entry)
        }
        return grouped
    }
    
    // The date sections we want to display, in order
    private let sections: [DateSection] = [.today, .tomorrow, .thisWeek, .thisMonth, .later]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Timeline sections
                    ForEach(sections, id: \ .self) { section in
                        if let entries = groupedTimelineEntries[section], !entries.isEmpty {
                            timelineSectionView(title: section.displayTitle, entries: entries)
                                .padding()
                                .background(AppColor.cardBackground)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Recent interactions section
                    if !viewModel.getRecentInteractions().isEmpty {
                        recentInteractionsView
                            .padding()
                            .background(AppColor.cardBackground)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            
            // Floating Action Button (FAB) at bottom right
            Button(action: {
                addLifeEventFlow = .selectPerson
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(AppColor.accent))
                    .shadow(radius: 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(trailing: EmptyView())
        .sheet(item: $addLifeEventFlow) { flow in
            switch flow {
            case .selectPerson:
                SelectPersonForEventView(viewModel: viewModel) { person in
                    addLifeEventFlow = .editEvent(person)
                }
            case .editEvent(let person):
                LifeEventEditView(event: nil) { savedEvent in
                    viewModel.addLifeEvent(for: person.id, event: savedEvent)
                    addLifeEventFlow = nil
                }
            }
        }
    }
    
    private func timelineSectionView(title: String, entries: [TimelineEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            ForEach(entries) { entry in
                timelineEntryRow(entry)
                
                if entry != entries.last {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
    }
    
    private func timelineEntryRow(_ entry: TimelineEntry) -> some View {
        // Determine destination based on entry type
        let destination: AnyView
        if let personId = entry.personId, let person = viewModel.personStore.people.first(where: { $0.id == personId }) {
            destination = AnyView(PersonDetailView(viewModel: viewModel, person: person))
        } else if entry.entryType == .connectionGoal {
            // Placeholder for Goal Detail View
            destination = AnyView(Text("Goal Detail View for \(entry.title)"))
        } else {
            // Fallback if no specific navigation target
            destination = AnyView(Text("Details for \(entry.title)"))
        }
        
        return NavigationLink(destination: destination) {
            HStack(alignment: .top, spacing: 12) {
                // Icon based on entry type
                Image(systemName: entry.iconName)
                    .foregroundColor(entry.iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if entry.showDate {
                            Spacer()
                            Text(entry.formattedDate)
                                .font(.caption)
                                .foregroundColor(AppColor.secondaryText)
                        }
                    }
                    
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // Ensures the link row looks clean
    }
    
    private var recentInteractionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Interactions")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            // Group recent interactions by date
            let interactions = viewModel.getRecentInteractions()
            let groupedInteractions = Dictionary(grouping: interactions) { Calendar.current.startOfDay(for: $0.date) }
            let sortedDates = groupedInteractions.keys.sorted(by: >)
            
            ForEach(sortedDates.prefix(5), id: \.self) { date in
                if let interactionsForDate = groupedInteractions[date] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColor.secondaryText)
                            .padding(.leading, 36)
                        
                        ForEach(interactionsForDate) { interaction in
                            if let person = viewModel.personStore.people.first(where: { $0.id == interaction.personId }) {
                                recentInteractionRow(interaction: interaction, person: person)
                                
                                if interaction != interactionsForDate.last {
                                    Divider()
                                        .padding(.leading, 36)
                                }
                            }
                        }
                    }
                    
                    // Check if this date is not the last one in the *visible* list
                    if date != sortedDates.prefix(5).last {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func recentInteractionRow(interaction: InteractionWithMood, person: Person) -> some View {
        // Wrap this row in a NavigationLink as well
        NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
            HStack(alignment: .top, spacing: 12) {
                // Icon based on interaction type
                Image(systemName: interaction.interaction.type.iconName)
                    .foregroundColor(AppColor.accent)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(person.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let mood = interaction.mood {
                            Text(mood.emoji)
                                .font(.subheadline)
                        }
                    }
                    
                    if let note = interaction.interaction.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                            .lineLimit(2)
                    } else {
                        Text("\(interaction.interaction.type.rawValue) interaction")
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                            .italic()
                    }
                }
                 Spacer() // Pushes content left, chevron appears right
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

// Define date sections for timeline grouping
enum DateSection: Hashable {
    case today
    case tomorrow
    case thisWeek
    case thisMonth
    case later
    
    var displayTitle: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .later: return "Coming Up"
        }
    }
}

// Timeline entry struct for unified timeline display
struct TimelineEntry: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let date: Date
    let iconName: String
    let iconColor: Color
    let entryType: TimelineEntryType
    let personId: UUID?
    let action: () -> Void
    
    // Manually implement Equatable, ignoring the action closure
    static func == (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.date == rhs.date &&
               lhs.iconName == rhs.iconName &&
               lhs.iconColor == rhs.iconColor &&
               lhs.entryType == rhs.entryType &&
               lhs.personId == rhs.personId
    }
    
    var showDate: Bool {
        switch entryType {
        case .birthday, .anniversary, .lifeEvent: return true
        default: return false
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var dateSection: DateSection {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let entryDate = calendar.startOfDay(for: date)
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today)!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: today)!
        
        if calendar.isDate(entryDate, inSameDayAs: today) {
            return .today
        } else if calendar.isDate(entryDate, inSameDayAs: tomorrow) {
            return .tomorrow
        } else if entryDate < weekEnd {
            return .thisWeek
        } else if entryDate < monthEnd {
            return .thisMonth
        } else {
            return .later
        }
    }
}

enum TimelineEntryType {
    case birthday
    case anniversary
    case scheduledInteraction
    case suggestedInteraction
    case lifeEvent
    case connectionGoal
}

// Interaction with optional mood tracking
struct InteractionWithMood: Identifiable, Equatable {
    let id = UUID()
    let interaction: InteractionLog
    let personId: UUID
    let mood: Mood?
    let date: Date
    
    init(interaction: InteractionLog, personId: UUID, mood: Mood? = nil) {
        self.interaction = interaction
        self.personId = personId
        self.mood = mood
        self.date = interaction.date
    }
}

// Mood enum for tracking how you felt after an interaction
enum Mood: String, Codable, CaseIterable {
    case energized = "Energized"
    case happy = "Happy"
    case neutral = "Neutral"
    case drained = "Drained"
    case stressed = "Stressed"
    
    var emoji: String {
        switch self {
        case .energized: return "⚡️"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .drained: return "😴"
        case .stressed: return "😓"
        }
    }
    
    var color: Color {
        switch self {
        case .energized: return .green
        case .happy: return .yellow
        case .neutral: return .gray
        case .drained: return .blue
        case .stressed: return .red
        }
    }
}

// Preview
#Preview {
    TimelineView(viewModel: LienViewModel())
} 