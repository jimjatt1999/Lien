import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: LienViewModel
    @State private var selectedTab: Tab = .home // Keep track of the selected tab
    
    // Enum to represent tabs, useful for state management
    enum Tab {
        case home, goals, timeline, people, network
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)
            
            // Add the new Connection Goals View
            // Wrap in NavigationView as it contains its own title etc.
            ConnectionGoalsView(viewModel: viewModel)
                .tabItem { Label("Goals", systemImage: "target") } // Using 'target' icon
                .tag(Tab.goals)
            
            // Wrap TimelineView in its own NavigationView
            NavigationView {
                TimelineView(viewModel: viewModel)
            }
            .tabItem { Label("Timeline", systemImage: "calendar") }
            .tag(Tab.timeline)
            
            // Wrap PeopleListView in its own NavigationView (if not already)
            NavigationView {
                 PeopleListView(viewModel: viewModel)
            }
            .tabItem { Label("People", systemImage: "person.2.fill") }
            .tag(Tab.people)
            
            // Wrap NetworkView in its own NavigationView (if not already)
            NavigationView {
                 NetworkView(viewModel: viewModel)
            }
            .tabItem { Label("Network", systemImage: "globe.americas.fill") }
            .tag(Tab.network)
        }
        // Remove the .onAppear setup for navigateToPersonDetail, as it's handled differently now.
    }
}

#Preview {
    MainTabView(viewModel: LienViewModel())
        .environmentObject(AppManager()) // Add EnvironmentObject for preview if needed
} 