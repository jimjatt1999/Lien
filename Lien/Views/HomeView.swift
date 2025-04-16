import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var inspirationalQuote: String = ""
    @State private var showingSettingsSheet = false
    
    private let quotes = [
        "The two most powerful warriors are patience and time.",
        "Time you enjoy wasting is not wasted time.",
        "The best time to plant a tree was 20 years ago. The second best time is now.",
        "Yesterday is gone. Tomorrow has not yet come. We have only today.",
        "Time is what we want most, but what we use worst.",
        "All we have to decide is what to do with the time that is given us.",
        "No man ever steps in the same river twice, for it's not the same river and he's not the same man.",
        "The key is in not spending time, but in investing it.",
        "Life is long if you know how to use it.",
        "Time is the most valuable thing a man can spend."
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Life progress view
                    lifeProgressView
                    
                    // Inspirational quote
                    quoteView
                    
                    // Contacts due today
                    if !viewModel.dueTodayContacts.isEmpty {
                        dueTodayView
                    }
                    
                    // Recent interactions
                    recentInteractionsView
                    
                    // Life in perspective
                    lifeInPerspectiveView
                }
                .padding()
                .navigationTitle("Lien")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettingsSheet = true
                        }) {
                            Image(systemName: "gear")
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
            .background(AppColor.primaryBackground)
            .onAppear {
                // Set a random inspirational quote
                inspirationalQuote = quotes.randomElement() ?? quotes[0]
            }
        }
    }
    
    // MARK: - Component Views
    
    var lifeProgressView: some View {
        VStack(spacing: 16) {
            // Life progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Life Journey")
                    .font(.headline)
                    .foregroundColor(AppColor.text)
                
                HStack {
                    Text("\(viewModel.userProfile.age)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColor.text)
                    
                    Text("of \(viewModel.userProfile.lifeExpectancy)")
                        .font(.subheadline)
                        .foregroundColor(AppColor.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int((Double(viewModel.userProfile.age) / Double(viewModel.userProfile.lifeExpectancy)) * 100))%")
                        .font(.headline)
                        .foregroundColor(AppColor.text)
                }
                
                ProgressView(value: Double(viewModel.userProfile.age), total: Double(viewModel.userProfile.lifeExpectancy))
                    .tint(AppColor.accent)
            }
            .padding()
            .background(AppColor.secondaryBackground)
            .cornerRadius(12)
            
            // Remaining time metrics
            HStack(spacing: 12) {
                TimeMetricCard(value: "\(viewModel.userProfile.yearsRemaining)", unit: "Years")
                TimeMetricCard(value: "\(viewModel.userProfile.monthsRemaining)", unit: "Months")
                TimeMetricCard(value: "\(viewModel.userProfile.weeksRemaining)", unit: "Weeks")
            }
        }
    }
    
    var quoteView: some View {
        VStack(spacing: 16) {
            Text("\u{201C}")
                .font(.system(size: 60))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.accent.opacity(0.3))
                .padding(.bottom, -40)
            
            Text(inspirationalQuote)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColor.text)
                .padding(.horizontal)
            
            Text("\u{201D}")
                .font(.system(size: 60))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.accent.opacity(0.3))
                .padding(.top, -40)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .cornerRadius(12)
    }
    
    var dueTodayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Due Today")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            ForEach(viewModel.dueTodayContacts.prefix(3)) { contact in
                NavigationLink(destination: ContactDetailView(viewModel: viewModel, contact: contact)) {
                    DueContactRow(contact: contact)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if viewModel.dueTodayContacts.count > 3 {
                NavigationLink(destination: ContactListView(viewModel: viewModel)) {
                    Text("See all \(viewModel.dueTodayContacts.count) contacts due today")
                        .font(.subheadline)
                        .foregroundColor(AppColor.accent)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .cornerRadius(12)
    }
    
    var recentInteractionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Interactions")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            let recentContacts = viewModel.contactStore.contacts
                .filter { $0.lastContactDate != nil }
                .sorted { ($0.lastContactDate ?? Date.distantPast) > ($1.lastContactDate ?? Date.distantPast) }
                .prefix(3)
            
            if recentContacts.isEmpty {
                Text("No recent interactions recorded")
                    .foregroundColor(AppColor.secondaryText)
                    .italic()
                    .padding()
            } else {
                ForEach(Array(recentContacts)) { contact in
                    NavigationLink(destination: ContactDetailView(viewModel: viewModel, contact: contact)) {
                        HStack(spacing: 12) {
                            AvatarView(contact: contact, size: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .font(.headline)
                                    .foregroundColor(AppColor.text)
                                
                                if let lastContactDate = contact.lastContactDate {
                                    Text("Last contacted: \(DueContactRow.timeAgoSince(lastContactDate))")
                                        .font(.caption)
                                        .foregroundColor(AppColor.secondaryText)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .cornerRadius(12)
    }
    
    var lifeInPerspectiveView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Life in Perspective")
                .font(.headline)
                .foregroundColor(AppColor.text)
            
            Text("If the average person lives to \(viewModel.userProfile.lifeExpectancy), they'll experience approximately:")
                .font(.subheadline)
                .foregroundColor(AppColor.secondaryText)
            
            VStack(spacing: 12) {
                perspectiveItem(count: viewModel.userProfile.lifeExpectancy * 52, unit: "weekends")
                perspectiveItem(count: viewModel.userProfile.lifeExpectancy * 12, unit: "full moons")
                perspectiveItem(count: 5, unit: "total hours with your closest friends")
            }
            
            Text("Make each one count.")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(AppColor.accent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    struct TimeMetricCard: View {
        let value: String
        let unit: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.text)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColor.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    struct DueContactRow: View {
        let contact: Contact
        
        var body: some View {
            HStack(spacing: 12) {
                AvatarView(contact: contact, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(AppColor.text)
                    
                    if let lastContactDate = contact.lastContactDate {
                        Text("Last contacted: \(DueContactRow.timeAgoSince(lastContactDate))")
                            .font(.caption)
                            .foregroundColor(AppColor.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColor.accent)
            }
            .padding(.vertical, 8)
        }
        
        // Helper method to format time
        static func timeAgoSince(_ date: Date) -> String {
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
            
            if let day = components.day, day > 0 {
                return "\(day) \(day == 1 ? "day" : "days") ago"
            } else if let hour = components.hour, hour > 0 {
                return "\(hour) \(hour == 1 ? "hour" : "hours") ago"
            } else if let minute = components.minute, minute > 0 {
                return "\(minute) \(minute == 1 ? "minute" : "minutes") ago"
            } else {
                return "Just now"
            }
        }
    }
    
    func perspectiveItem(count: Int, unit: String) -> some View {
        HStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColor.accent)
                .frame(width: 60, alignment: .leading)
            
            Text(unit)
                .font(.body)
                .foregroundColor(AppColor.text)
            
            Spacer()
        }
    }
}

#Preview {
    HomeView(viewModel: LienViewModel())
} 