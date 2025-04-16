import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var showingSettingsSheet = false
    @State private var currentConnectionPrompt: String = "" // State for connection prompt

    // --- Connection Prompts --- 
    private let connectionPrompts = [
        "Who comes to mind right now? A quick hello can brighten their day.",
        "Even a short message shows you care.",
        "Reaching out strengthens the threads that connect us.",
        "What's one small way you can connect with someone today?",
        "A simple check-in can mean a lot.",
        "Who haven't you spoken to in a while?",
        "Thinking of someone? Let them know!",
        "Small connections build strong bonds.",
        
        // New Prompts
        "Ask a friend about their day. Really listen.",
        "Share a funny memory with a family member.",
        "Offer a word of encouragement to a colleague.",
        "Who supported you recently? Thank them.",
        "A simple \'thinking of you\' goes a long way.",
        "Plan a quick call, even just for 5 minutes.",
        "Send a photo that reminds you of someone.",
        "Is there someone you admire? Tell them why.",
        "Share an interesting article or song.",
        "Celebrate a small win with someone.",
        "Ask for advice, even if you don't strictly need it.",
        "Offer help, even if it's just listening.",
        "Recall an inside joke and share it.",
        "Compliment someone sincerely.",
        "Who makes you laugh? Reach out to them.",
        "Share something you learned recently.",
        "Just say hi. It's often enough.",
        "Consistency matters more than grand gestures.",
        "Be the friend you wish you had.",
        "Make time. Don't just find time.",
        "Vulnerability builds deeper connections.",
        "Ask open-ended questions.",
        "Put your phone away during conversations.",
        "Remember small details about people.",
        "Show up for the important moments.",
        "Forgiveness frees up energy for connection.",
        "Who could use your support right now?",
        "Don't assume, ask.",
        "Be genuinely curious about others.",
        "Every interaction is an opportunity.",
        
        // --- Batch 3: Deep, Funny, Fun --- 
        "Who challenged your perspective recently? Engage again.",
        "Ask someone: \'What made you smile today?\'",
        "Send a perfectly timed GIF or meme.",
        "Admit you were wrong about something trivial. It builds bridges.",
        "Who inspires you creatively? Let them know.",
        "\'Remember that time when...\' is a powerful starter.",
        "Share a ridiculous pun. Apologize later (or don\'t).",
        "Ask about someone\'s passion project.",
        "What\'s the weirdest dream you had recently? Share (if appropriate!).",
        "Offer to bring coffee or tea.",
        "Check in on someone who might be going through a tough time.",
        "Plan a low-pressure hangout, even virtual.",
        "Send a voice note instead of a text.",
        "Ask: \'What are you excited about this week?\'",
        "Share a picture of your pet doing something goofy.",
        "Who haven\'t you *physically* seen in a while? Make a plan.",
        "Recommend a book/movie/podcast you genuinely enjoyed.",
        "Confess a minor, funny mishap from your day.",
        "Ask someone about their favorite childhood memory.",
        "Debate something silly: pineapple on pizza? Best chip flavor?",
        "Express gratitude for a specific quality you admire in someone.",
        "Who pushes you to be better? Acknowledge it.",
        "\'Saw this and thought of you\' - even if it\'s slightly random.",
        "Initiate the conversation. Don\'t always wait.",
        "Ask for a recommendation (restaurant, music, etc.).",
        "Share a quick win from your day.",
        "Send a postcard (yes, really!).",
        "Challenge a friend to a silly online game.",
        "Talk about future hopes, big or small.",
        "Sometimes, just being present together is enough.",
        "What\'s one thing you appreciate about this connection?"
    ]
    // --- End Connection Prompts ---

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Header Section
                    headerSection
                    
                    // 2. Spontaneous Suggestion
                    if let suggestedPerson = viewModel.spontaneousSuggestion {
                        spontaneousSuggestionView(person: suggestedPerson)
                            .padding(.top, 5)
                    }

                    // 3. Connection Prompt (Moved up, outside card)
                    connectionPromptView
                        .padding(.horizontal) // Add horizontal padding
                        // Not in a card anymore

                    // --- Section Order Adjusted --- 

                    // 4. Merged Life Journey & Perspective Card
                    lifeProgressView // Now contains perspective items
                        .padding()
                        .background(AppColor.cardBackground)
                        .cornerRadius(12)
                    
                    // 5. Reach Out Suggestions Card 
                    if !viewModel.suggestedPeopleToReachOutTo.isEmpty {
                        reachOutSuggestionsView
                            .padding()
                            .background(AppColor.cardBackground)
                            .cornerRadius(12)
                    }

                    // 6. Upcoming Events Card (if any)
                    if !viewModel.upcomingEvents.isEmpty {
                        upcomingEventsView
                            .padding()
                            .background(AppColor.cardBackground)
                            .cornerRadius(12)
                    }
                }
                .padding() 
                .toolbar { // Keep existing toolbar
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingSettingsSheet = true }) {
                            Image(systemName: "person.circle").imageScale(.large)
                        }
                    }
                }
                .sheet(isPresented: $showingSettingsSheet) { // Keep existing sheet
                    NavigationView {
                        SettingsView(viewModel: viewModel)
                            .navigationTitle("Settings")
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea()) 
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { 
                viewModel.generateSpontaneousSuggestion()
                // Select initial connection prompt
                currentConnectionPrompt = connectionPrompts.randomElement() ?? connectionPrompts[0]
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) { // Increased spacing slightly
            Text(greeting)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 4) // Add some padding below greeting
            DateGridView() // Make DateGridView compact internally
        }
        .padding(.bottom) // Add padding below the header section
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let baseGreeting: String
        switch hour {
        case 6..<12: baseGreeting = "Good morning."
        case 12..<18: baseGreeting = "Good afternoon."
        default: baseGreeting = "Good evening."
        }
        
        // Add name if available and not empty
        let userName = viewModel.userProfile.name
        if !userName.isEmpty {
            return baseGreeting.replacingOccurrences(of: ".", with: ", \(userName).")
        } else {
            return baseGreeting
        }
    }
    
    // MARK: - Spontaneous Suggestion View (Subtle)
    
    @ViewBuilder
    private func spontaneousSuggestionView(person: Person) -> some View {
        HStack {
            Text("Thinking of...")
                .font(.callout)
                .foregroundColor(.secondary)
            
            AvatarView(person: person, size: 25) // Small avatar
            
            Text(person.name)
                .font(.callout)
                .fontWeight(.medium)
            
            Spacer()
            
            // Optional: Button to refresh?
            /*
            Button { viewModel.generateSpontaneousSuggestion() } label: {
                Image(systemName: "arrow.clockwise.circle")
            }
            .buttonStyle(BorderlessButtonStyle())
            */
        }
        .padding(.horizontal) // Only horizontal padding to keep it less card-like
        .contentShape(Rectangle()) // Make HStack tappable
        .onTapGesture {
            // Navigate to person? For now, maybe just refresh
             viewModel.generateSpontaneousSuggestion()
        }
    }
    
    // MARK: - Component Views (Cards)
    
    var lifeProgressView: some View {
        VStack(alignment: .leading, spacing: 15) { // Increased spacing between sections
            // --- Original Life Journey --- 
            VStack(alignment: .leading, spacing: 8) { 
                Text("Your Life Journey")
                    .font(.headline)
                    .foregroundColor(AppColor.text)

                HStack {
                    Text("Age \(viewModel.userProfile.age)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.text)
                    Spacer()
                    Text("\(viewModel.userProfile.yearsRemaining) years remaining")
                        .font(.subheadline)
                        .foregroundColor(AppColor.secondaryText)
                }
                ProgressView(value: Double(viewModel.userProfile.age), total: Double(viewModel.userProfile.lifeExpectancy))
                    .tint(AppColor.accent)
                    .padding(.top, 4)
            }
            // --- End Original Life Journey ---

            Divider().padding(.vertical, 5) // Add divider

            // --- Merged Perspective Items --- 
            VStack(alignment: .leading, spacing: 8) { // Reduced spacing
                 Text("Approximate experiences remaining:")
                     .font(.subheadline)
                     .foregroundColor(AppColor.secondaryText)
                
                 VStack(spacing: 8) { // Tighter spacing for items
                     perspectiveItemMerged(icon: "calendar", count: viewModel.userProfile.yearsRemaining * 52, unit: "weekends")
                     perspectiveItemMerged(icon: "moon.fill", count: viewModel.userProfile.yearsRemaining * 12, unit: "full moons")
                     perspectiveItemMerged(icon: "figure.stand.line.dotted.figure.stand", count: viewModel.userProfile.yearsRemaining * 4, unit: "seasons")
                 }
                 // .padding(.top, 4) // Removed extra top padding
            }
            // --- End Merged Perspective --- 
            
             // Centered reminder text from perspective view
             Text("Make each moment count.")
                 .font(.footnote)
                 .italic()
                 .foregroundColor(AppColor.accent)
                 .frame(maxWidth: .infinity, alignment: .center)
                 .padding(.top, 8)
        }
    }
    
    // Helper for merged perspective items (kept local to the merged view)
    private func perspectiveItemMerged(icon: String, count: Int, unit: String) -> some View {
         HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout) // Slightly smaller icon than before
                .foregroundColor(AppColor.accent)
                .frame(width: 20) // Adjusted frame
            
            Text("\(count) \(unit)")
                .font(.caption) // Smaller font
                .foregroundColor(AppColor.text)
            
            Spacer()
        }
        .padding(.vertical, 0) // Minimal vertical padding
    }
    
    var reachOutSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time to Connect")
                .font(.headline)
                .foregroundColor(AppColor.text)

            // Display suggestions
            let suggestionsToShow = viewModel.suggestedPeopleToReachOutTo // Show all suggestions
            ForEach(suggestionsToShow) { person in
                NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
                    HStack {
                        AvatarView(person: person, size: 40)
                        VStack(alignment: .leading) {
                            Text(person.name).font(.subheadline).fontWeight(.medium)
                            // Show relationship status for context
                            Text(person.relationshipStatus.description)
                                .font(.caption)
                                .foregroundColor(person.relationshipStatus.color)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                             .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if person != suggestionsToShow.last {
                     Divider().padding(.leading, 52)
                 }
            }

            // Link to Connection Goals view if there are suggestions
            if !suggestionsToShow.isEmpty {
                 NavigationLink(destination: ConnectionGoalsView(viewModel: viewModel)) {
                     HStack {
                         Spacer()
                         Text("View All Goals")
                             .font(.subheadline)
                         Image(systemName: "arrow.right")
                             .font(.subheadline)
                     }
                     .foregroundColor(AppColor.accent)
                 }
                 .padding(.top, 8)
             }
        }
    }
    
    var connectionPromptView: some View {
        Text(currentConnectionPrompt)
            .font(.callout) // Increased font size from .caption
            .italic()
            .foregroundColor(AppColor.secondaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8) // Increased vertical padding slightly
            .contentShape(Rectangle()) // Make it tappable
            .onTapGesture {
                 currentConnectionPrompt = connectionPrompts.randomElement() ?? connectionPrompts[0]
            }
    }
    
    var upcomingEventsView: some View {
        VStack(alignment: .leading, spacing: 12) { // Adjusted spacing
            Text("Upcoming Events")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            ForEach(viewModel.upcomingEvents.prefix(3)) { event in // Limit visible events
                if let person = viewModel.personStore.people.first(where: { $0.id == event.id }) {
                    NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
                        HStack(spacing: 12) {
                            AvatarView(person: person, size: 40)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.personName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\\(event.eventType) • \\(event.date, style: .date)") // Compact format
                                    .font(.caption)
                                    .foregroundColor(AppColor.secondaryText)
                            }
                            Spacer()
                            Text("\\(event.daysAway)d") // Compact days away
                                .font(.caption)
                                .foregroundColor(AppColor.secondaryText)
                                .padding(6)
                                .background(AppColor.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    if event.id != viewModel.upcomingEvents.prefix(3).last?.id {
                        Divider().padding(.leading, 52) // Add divider between items
                    }
                }
            }
             // Optional: Link to see all events if needed
        }
         // Remove internal padding/background/cornerRadius, handled by the caller
    }
    
    // MARK: - Date Grid View Component (Compact)
    
    struct DateGridView: View {
        let calendar = Calendar.current
        let today = Date()
        let daysToShow = 7
        
        var weekDates: [Date] {
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                return []
            }
            return (0..<daysToShow).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
            }
        }
        
        var body: some View {
            HStack(spacing: 4) { // Reduced spacing
                ForEach(weekDates, id: \.self) { date in // Corrected id syntax
                    VStack(spacing: 2) { // Reduced spacing
                        Text(dayOfWeekFormatter.string(from: date).uppercased())
                            .font(.caption2) // Smaller font
                            .foregroundColor(isToday(date) ? AppColor.accent : .secondary)
                        Text(dayOfMonthFormatter.string(from: date))
                            .font(.footnote) // Smaller font
                            .fontWeight(isToday(date) ? .bold : .regular)
                            .foregroundColor(isToday(date) ? AppColor.text : .secondary)
                            .frame(minWidth: 20, minHeight: 20) // Ensure minimum size
                            .background(
                                Circle()
                                    .fill(isToday(date) ? AppColor.accent.opacity(0.2) : Color.clear) // Circle highlight for today
                            )
                    }
                    .padding(4) // Reduced padding
                    // Removed explicit background/cornerRadius for individual items
                }
            }
        }
        
        private func isToday(_ date: Date) -> Bool {
            calendar.isDate(date, inSameDayAs: today)
        }
        
        private var dayOfWeekFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "E" // Abbreviated day name (e.g., "Mon")
            return formatter
        }
        
        private var dayOfMonthFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "d" // Day of month
            return formatter
        }
    }
}

#Preview {
    HomeView(viewModel: LienViewModel())
        .environmentObject(AppManager()) // Ensure AppManager is available for preview
} 
