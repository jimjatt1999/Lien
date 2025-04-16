import SwiftUI

struct ConnectionGoalCardView: View {
    let entry: LienViewModel.ConnectionGoalEntry
    // Add viewModel if actions are needed directly from the card (e.g., quick log button)
    // @ObservedObject var viewModel: LienViewModel 

    // Use the same helpers as the Row for consistency
    private var progress: Double {
        guard let intervalDays = entry.person.meetFrequency.intervalDays, intervalDays > 0 else { return 0.0 }
        guard let daysSince = entry.person.daysSinceLastContact else { return 0.0 }
        return max(0.0, min(1.0, Double(daysSince) / Double(intervalDays)))
    }

    private var statusColor: Color {
        switch entry.status {
        case .overdue: return .red
        case .dueIn(let days): return days == 0 ? .orange : .blue
        case .neverContacted: return .purple
        case .noGoalSet: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Section: Image, Name, Relationship
            HStack(spacing: 12) {
                PersonImageView(person: entry.person, size: 50)
                VStack(alignment: .leading) {
                    Text(entry.person.name)
                        .font(.title3.weight(.semibold))
                    Text(entry.person.relationshipType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer() // Pushes content left
            }

            Divider()

            // Middle Section: Status Text and Progress Ring
            HStack {
                statusText // Reuse the status text logic
                Spacer()
                progressRing // Extracted progress ring logic
            }
            
            // Optional: Add Action Buttons (e.g., Log Interaction, View Details)
            // Divider()
            // HStack { ... buttons ... }

        }
        .padding()
        .background(AppColor.cardBackground) // Use card background color
        .cornerRadius(12)
        // Add shadow for card effect
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // Extracted Progress Ring View
    @ViewBuilder
    private var progressRing: some View {
        ZStack {
             Circle()
                 .stroke(statusColor.opacity(0.2), lineWidth: 5)
             Circle()
                 .trim(from: 0.0, to: progress)
                 .stroke(statusColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                 .rotationEffect(.degrees(-90))
         }
         .frame(width: 45, height: 45)
    }
    
    // Reusing status text logic (similar to row)
    @ViewBuilder
    private var statusText: some View {
        VStack(alignment: .leading) { // Align leading for card
            switch entry.status {
            case .overdue(let days):
                Text("Overdue")
                    .font(.body.weight(.semibold))
                    .foregroundColor(statusColor)
                Text("by \(days) day\(days == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .dueIn(let days):
                 if days == 0 {
                      Text("Due Today")
                          .font(.body.weight(.semibold))
                          .foregroundColor(statusColor)
                  } else {
                      Text("Due In")
                          .font(.body.weight(.semibold))
                          .foregroundColor(statusColor)
                      Text("\(days) day\(days == 1 ? "" : "s")")
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                  }
             case .neverContacted:
                 Text("Connect Soon")
                     .font(.body.weight(.semibold))
                     .foregroundColor(statusColor)
             case .noGoalSet:
                 Text("No Goal Set")
                     .font(.body.weight(.semibold))
                     .foregroundColor(statusColor)
             }
         }
    }
}

#Preview {
    // Create a ViewModel with some sample data for preview
    let previewViewModel = LienViewModel()
    
    // Use the same sample data as ConnectionGoalsView Preview
    var person1 = Person(name: "Alex Overdue", relationshipType: .friend, meetFrequency: .weekly)
    person1.lastContactDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) 
    
    var person2 = Person(name: "Ben Due Soon", relationshipType: .family, meetFrequency: .monthly)
    person2.lastContactDate = Calendar.current.date(byAdding: .day, value: -25, to: Date())

    var person3 = Person(name: "Charlie Never", relationshipType: .colleague, meetFrequency: .quarterly)

    var person4 = Person(name: "Diana Due Today", relationshipType: .closeFriend, meetFrequency: .biweekly)
    person4.lastContactDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
    
    previewViewModel.personStore.people = [person1, person2, person3, person4]
    
    // Return one or more cards in a ScrollView for previewing layout
    return ScrollView {
        VStack {
            ForEach(previewViewModel.connectionGoalEntries) { entry in
                ConnectionGoalCardView(entry: entry)
            }
        }
        .padding()
    }
    .environmentObject(AppManager())
    .background(Color(.systemGroupedBackground))
} 