import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: LienViewModel
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ContactListView(viewModel: viewModel)
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
        }
    }
}

#Preview {
    MainTabView(viewModel: LienViewModel())
} 