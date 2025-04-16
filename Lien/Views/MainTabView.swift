import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: LienViewModel
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            PeopleListView(viewModel: viewModel)
                .tabItem {
                    Label("People", systemImage: "person.2.fill")
                }
            
            NetworkView(viewModel: viewModel)
                .tabItem {
                    Label("Network", systemImage: "globe.americas.fill")
                }
        }
    }
}

#Preview {
    MainTabView(viewModel: LienViewModel())
} 