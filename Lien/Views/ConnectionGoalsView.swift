import SwiftUI

struct ConnectionGoalsView: View {
    @ObservedObject var viewModel: LienViewModel
    @EnvironmentObject var appManager: AppManager
    
    // MARK: - State Variables
    @State private var filterOption: FilterOption = .all // Default filter

    // MARK: - Enums
    enum FilterOption: String, CaseIterable, Hashable, Identifiable { // Added Identifiable
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case neverContacted = "Never Contacted"
        // Can add more later: case byRelationship(Person.RelationshipType)
        
        // Conformance to Identifiable
        var id: String { self.rawValue }
    }

    // MARK: - Computed Properties
    private var filteredEntries: [LienViewModel.ConnectionGoalEntry] {
        // Apply filtering based on filterOption
        switch filterOption {
        case .all:
            return viewModel.connectionGoalEntries
        case .overdue:
            return viewModel.connectionGoalEntries.filter { entry in
                if case .overdue = entry.status { return true } else { return false }
            }
        case .dueSoon:
            return viewModel.connectionGoalEntries.filter { entry in
                if case .dueIn = entry.status { return true } else { return false }
            }
        case .neverContacted:
            return viewModel.connectionGoalEntries.filter { entry in
                if case .neverContacted = entry.status { return true } else { return false }
            }
        }
        // Sorting is handled by the default order in viewModel.connectionGoalEntries
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            listView
            .navigationTitle("Connection Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // --- Filter Section ---
                        Text("Filter By Status").font(.caption).foregroundColor(.secondary)
                        Picker("Filter", selection: $filterOption) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        // --- Add Sort Section later if needed ---
                        // Divider()
                        // Text("Sort By...")
                    } label: {
                        // Indicate if a filter is active
                        Label("Filter", systemImage: filterOption == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
        }
        .fontDesign(appManager.appFontDesign.swiftUIFontDesign)
    }
    
    // MARK: - Subviews
    private var listView: some View {
        List {
            // Use the filteredEntries computed property
            ForEach(filteredEntries) { entry in
                NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: entry.person)) {
                    ConnectionGoalRow(entry: entry)
                }
            }
        }
        .listStyle(.plain) // Use plain style
    }
}

struct ConnectionGoalRow: View {
    let entry: LienViewModel.ConnectionGoalEntry
    
    // Calculate progress for the ring
    private var progress: Double {
        guard let intervalDays = entry.person.meetFrequency.intervalDays, intervalDays > 0 else { return 0.0 }
        guard let daysSince = entry.person.daysSinceLastContact else { return 0.0 } // If never contacted, progress is 0
        
        // Clamp progress between 0 and 1
        return max(0.0, min(1.0, Double(daysSince) / Double(intervalDays)))
    }
    
    // Determine color based on status
    private var statusColor: Color {
        switch entry.status {
        case .overdue:
            return .red
        case .dueIn(let days):
            return days == 0 ? .orange : .blue
        case .neverContacted:
            return .purple
        case .noGoalSet:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile Image/Initials
            PersonImageView(person: entry.person, size: 40)
            
            // Person Info
            VStack(alignment: .leading) {
                Text(entry.person.name)
                    .font(.headline)
                Text(entry.person.relationshipType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress Ring and Status Text
            progressStatusView
        }
        .padding(.vertical, 8)
    }
    
    // Combined Progress Ring and Text Status
    @ViewBuilder
    private var progressStatusView: some View {
        HStack(spacing: 8) {
            ZStack {
                // Background ring
                 Circle()
                     .stroke(statusColor.opacity(0.2), lineWidth: 4)
                // Progress ring
                 Circle()
                     .trim(from: 0.0, to: progress)
                     .stroke(statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                     .rotationEffect(.degrees(-90))
                 
                // Optional: Add percentage text inside if desired
                 // Text("\(Int(progress * 100))%")
                 //     .font(.system(size: 10))
                 //     .foregroundColor(statusColor)
             }
             .frame(width: 30, height: 30)
            
            // Status Text
            statusText
        }
    }
    
    // Helper for the status text part
    @ViewBuilder
    private var statusText: some View {
        VStack(alignment: .trailing) {
            switch entry.status {
            case .overdue(let days):
                Text("Overdue")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(statusColor)
                Text("by \(days) day\(days == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .dueIn(let days):
                 if days == 0 {
                      Text("Due Today")
                          .font(.caption.weight(.semibold))
                          .foregroundColor(statusColor)
                  } else {
                      Text("Due In")
                          .font(.caption.weight(.semibold))
                          .foregroundColor(statusColor)
                      Text("\(days) day\(days == 1 ? "" : "s")")
                         .font(.caption2)
                         .foregroundColor(.secondary)
                  }
             case .neverContacted:
                 Text("Connect Soon")
                     .font(.caption.weight(.semibold))
                     .foregroundColor(statusColor)
             case .noGoalSet:
                 Text("No Goal Set")
                     .font(.caption.weight(.semibold))
                     .foregroundColor(statusColor)
             }
         }
         .frame(minWidth: 60, alignment: .trailing) // Give text some min width
    }
}

// Preview needs adjustment if PersonImageView isn't available globally
// or needs specific setup.
#Preview {
    // Create a ViewModel with some sample data for preview
    let previewViewModel = LienViewModel()
    
    // --- Create Sample People for Preview ---
    var person1 = Person(name: "Alex Overdue", relationshipType: .friend, meetFrequency: .weekly)
    person1.lastContactDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) // 10 days ago
    
    var person2 = Person(name: "Ben Due Soon", relationshipType: .family, meetFrequency: .monthly)
    person2.lastContactDate = Calendar.current.date(byAdding: .day, value: -25, to: Date()) // 25 days ago (due in ~5 days)

    var person3 = Person(name: "Charlie Never", relationshipType: .colleague, meetFrequency: .quarterly)
    // No lastContactDate

    var person4 = Person(name: "Diana Due Today", relationshipType: .closeFriend, meetFrequency: .biweekly)
    person4.lastContactDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) // 14 days ago
    
    previewViewModel.personStore.people = [person1, person2, person3, person4]
    // --- End Sample People ---

    return ConnectionGoalsView(viewModel: previewViewModel)
        .environmentObject(AppManager())
} 