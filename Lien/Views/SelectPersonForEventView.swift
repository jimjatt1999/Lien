import SwiftUI

struct SelectPersonForEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LienViewModel
    var onPersonSelected: (Person) -> Void
    
    @State private var searchText: String = ""
    
    var filteredPeople: [Person] {
        if searchText.isEmpty {
            return viewModel.personStore.people.sorted { $0.name < $1.name }
        } else {
            return viewModel.personStore.people.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search person...")
                
                List {
                    if filteredPeople.isEmpty {
                        Text(searchText.isEmpty ? "No people found." : "No people match your search.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredPeople) { person in
                            Button {
                                onPersonSelected(person)
                            } label: {
                                HStack {
                                    AvatarView(person: person, size: 30)
                                    Text(person.name)
                                    Spacer()
                                }
                                .foregroundColor(.primary) // Ensure text color is standard
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SelectPersonForEventView(viewModel: LienViewModel()) { person in
        print("Selected: \(person.name)")
    }
} 