import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var inspirationalQuote: String = ""
    @State private var showingSettingsSheet = false
    
    // Expanded and themed quotes
    private let quotes = [
        // On Connection & Relationships
        "The meeting of two personalities is like the contact of two chemical substances: if there is any reaction, both are transformed. - Carl Jung",
        "Shared joy is a double joy; shared sorrow is half a sorrow. - Swedish Proverb",
        "There is no substitute for the comfort supplied by the steadfast truths of life shared with a good friend. - Anonymous",
        "In everyone's life, at some time, our inner fire goes out. It is then burst into flame by an encounter with another human being. - Albert Schweitzer",
        "We are like islands in the sea, separate on the surface but connected in the deep. - William James",
        "Friendship is born at that moment when one person says to another, 'What! You too? I thought I was the only one.' - C.S. Lewis",
        "The best way to keep your friends is not to give them away. - Wilson Mizner",
        
        // On Time & Presence
        "Time is the coin of your life. It is the only coin you have, and only you can determine how it will be spent. - Carl Sandburg",
        "The present moment is filled with joy and happiness. If you are attentive, you will see it. - Thich Nhat Hanh",
        "Realize deeply that the present moment is all you have. Make the NOW the primary focus of your life. - Eckhart Tolle",
        "Yesterday is history, tomorrow is a mystery, today is a gift of God, which is why we call it the present. - Bill Keane",
        "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment. - Buddha",
        "How we spend our days is, of course, how we spend our lives. - Annie Dillard",
        
        // On Philosophy & Life
        "Waste no more time arguing about what a good man should be. Be one. - Marcus Aurelius",
        "The unexamined life is not worth living. - Socrates",
        "It is not that we have a short time to live, but that we waste a lot of it. - Seneca",
        "He who lives in harmony with himself lives in harmony with the universe. - Marcus Aurelius",
        "The only true wisdom is in knowing you know nothing. - Socrates",
        "Happiness is not something ready made. It comes from your own actions. - Dalai Lama",
        "Be yourself; everyone else is already taken. - Oscar Wilde"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section (Greeting + Date Grid) - No card background for header
                    headerSection
                    
                    // Spontaneous Suggestion (Subtle)
                    if let suggestedPerson = viewModel.spontaneousSuggestion {
                        spontaneousSuggestionView(person: suggestedPerson)
                            .padding(.top, 5) // Add some space above
                    }
                    
                    // Sections as Cards
                    lifeProgressView
                        .padding()
                        .background(AppColor.cardBackground)
                        .cornerRadius(12)

                    quoteView
                        .padding()
                        .background(AppColor.cardBackground)
                        .cornerRadius(12)

                    if !viewModel.suggestedPeopleToReachOutTo.isEmpty {
                        reachOutSuggestionsView
                            .padding()
                            .background(AppColor.cardBackground)
                            .cornerRadius(12)
                    }

                    if !viewModel.upcomingEvents.isEmpty {
                        upcomingEventsView
                            .padding()
                            .background(AppColor.cardBackground)
                            .cornerRadius(12)
                    }

                    lifeInPerspectiveView
                        .padding()
                        .background(AppColor.cardBackground)
                        .cornerRadius(12)
                }
                .padding() // Add padding around the main VStack
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettingsSheet = true
                        }) {
                            Image(systemName: "person.circle")
                                .imageScale(.large)
                        }
                    }
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    NavigationView {
                        SettingsView(viewModel: viewModel)
                            .navigationTitle("Settings")
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Use standard grouped background
            .navigationBarTitleDisplayMode(.inline) // Use inline title to give more space to header
            .onAppear {
                inspirationalQuote = quotes.randomElement() ?? quotes[0]
                viewModel.generateSpontaneousSuggestion() // Generate suggestion on appear
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
        VStack(alignment: .leading, spacing: 8) { // Reduced spacing inside card
            Text("Your Life Journey")
                .font(.headline)
                .foregroundColor(AppColor.text)

            HStack {
                Text("Age \(viewModel.userProfile.age)") // Combined text
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
                .padding(.top, 4) // Add small padding above progress bar
        }
        // Remove internal padding/background/cornerRadius, handled by the caller
    }
    
    var quoteView: some View {
        VStack(alignment: .center, spacing: 8) {
            let quoteParts = inspirationalQuote.components(separatedBy: " - ")
            let quoteText = quoteParts.first ?? inspirationalQuote
            let authorText = quoteParts.count > 1 ? quoteParts.last : nil
            
            Text("\"\(quoteText)\"")
                .font(.system(.body, design: .serif)) // Slightly smaller font
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.text)
                .padding(.horizontal)
            
            if let author = authorText, !author.isEmpty {
                Text("- \(author)") // Corrected interpolation
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(AppColor.secondaryText)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity) // Ensure VStack fills the width
        // Remove internal padding/background/cornerRadius, handled by the caller
    }
    
    var reachOutSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) { // Adjusted spacing
            Text("Time to Connect") // Simplified title
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            // Display first few suggestions
            ForEach(viewModel.suggestedPeopleToReachOutTo.prefix(3)) { person in
                NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
                    // Consider using a slightly richer row here if needed
                    HStack {
                        AvatarView(person: person, size: 40)
                        VStack(alignment: .leading) {
                            Text(person.name).font(.subheadline).fontWeight(.medium)
                            Text(person.relationshipStatus.description) // Use description property
                                .font(.caption)
                                .foregroundColor(person.relationshipStatus.color)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                             .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle for links in List/ForEach
                 if person != viewModel.suggestedPeopleToReachOutTo.prefix(3).last {
                     Divider().padding(.leading, 52) // Add divider between items
                 }
            }
            
            // Link to see all
            if viewModel.suggestedPeopleToReachOutTo.count > 3 {
                NavigationLink(destination: PeopleListView(viewModel: viewModel, initialFilter: PeopleListFilter.suggested)) { // Pass fully qualified filter
                    HStack {
                        Spacer()
                        Text("See all \(viewModel.suggestedPeopleToReachOutTo.count)")
                            .font(.subheadline)
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                    .foregroundColor(AppColor.accent)
                }
                .padding(.top, 8)
            }
        }
        // Remove internal padding/background/cornerRadius, handled by the caller
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
    
    var lifeInPerspectiveView: some View {
        VStack(alignment: .leading, spacing: 12) { // Adjusted spacing
            Text("Life in Perspective")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            // Simplified text
            Text("Approximate experiences remaining:")
                .font(.subheadline)
                .foregroundColor(AppColor.secondaryText)
            
            VStack(spacing: 10) { // Tighter spacing for items
                perspectiveItem(icon: "calendar", count: viewModel.userProfile.yearsRemaining * 52, unit: "weekends")
                perspectiveItem(icon: "moon.fill", count: viewModel.userProfile.yearsRemaining * 12, unit: "full moons")
                perspectiveItem(icon: "figure.stand.line.dotted.figure.stand", count: viewModel.userProfile.yearsRemaining * 4, unit: "seasons")
            }
            .padding(.top, 4)

            // Centered quote/reminder
            Text("Make each moment count.")
                .font(.footnote) // Smaller font
                .italic()
                .foregroundColor(AppColor.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
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
    
    // MARK: - Helper Views
    
    func perspectiveItem(icon: String, count: Int, unit: String) -> some View {
         HStack(spacing: 10) { // Reduced spacing
            Image(systemName: icon)
                .font(.body) // Smaller icon
                .foregroundColor(AppColor.accent)
                .frame(width: 25) // Adjusted frame
            
            // Combine count and unit
            Text("\(count) \(unit)") // Corrected interpolation
                .font(.callout) // Smaller font
                .foregroundColor(AppColor.text)
            
            Spacer()
        }
        .padding(.vertical, 1) // Reduced vertical padding
    }
}

#Preview {
    HomeView(viewModel: LienViewModel())
} 
