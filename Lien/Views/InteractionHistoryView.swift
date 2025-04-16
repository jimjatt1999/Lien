import SwiftUI

struct InteractionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    let person: Person

    // Sort history once, most recent first
    private var sortedHistory: [InteractionLog] {
        person.interactionHistory.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            List {
                if sortedHistory.isEmpty {
                    Text("No interactions recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedHistory) { log in
                        interactionRow(log)
                    }
                }
            }
            .navigationTitle("\(person.name) History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    // Row view for a single interaction log
    private func interactionRow(_ log: InteractionLog) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon for interaction type
            Image(systemName: log.type.iconName)
                .font(.callout) // Slightly larger icon
                .foregroundColor(AppColor.secondaryText)
                .frame(width: 20, alignment: .center)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Date
                    Text(log.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer() // Pushes mood to the right
                    
                    // Show mood if available
                    if let mood = person.interactionMoods[log.id] {
                        Text(mood.emoji)
                            .font(.headline)
                    }
                }
                
                // Location (if available for meetings)
                if log.type == .meeting, let location = log.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                    }
                }

                // Note (if available)
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundColor(AppColor.text)
                } else {
                    // Show type explicitly if no note
                    Text("Logged \(log.type.rawValue) interaction")
                        .font(.body)
                        .foregroundColor(AppColor.secondaryText)
                        .italic()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Preview requires a Person with interaction history
#Preview {
    // Create mock data for preview
    var previewPerson = Person(name: "Jane Doe", relationshipType: .friend, meetFrequency: .monthly)
    let interaction1 = InteractionLog(type: .meeting, note: "Coffee chat about project X")
    var interaction2 = InteractionLog(type: .call)
    var interaction3 = InteractionLog(type: .meeting, note: "Lunch meeting")
    interaction3.location = "Downtown Cafe"
    let interaction4 = InteractionLog(type: .message)
    
    previewPerson.interactionHistory = [interaction1, interaction2, interaction3, interaction4]
    previewPerson.interactionMoods[interaction1.id] = .energized
    previewPerson.interactionMoods[interaction3.id] = .happy

    return InteractionHistoryView(person: previewPerson)
} 