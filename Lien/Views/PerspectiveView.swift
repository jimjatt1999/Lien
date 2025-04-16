import SwiftUI

struct PerspectiveView: View {
    @ObservedObject var viewModel: LienViewModel
    
    // State to hold the currently displayed perspective text
    @State private var currentPerspective: String = ""
    
    // Potential perspectives to cycle through
    private func generatePerspectives() -> [String] {
        var perspectives: [String] = [
            "Context: ~8 billion people on Earth.",
            "Focus: You have \(viewModel.userProfile.weeksRemaining) estimated weeks remaining.",
            "Research suggests most people maintain ~150 meaningful relationships.",
            
            // New Encouragement / Connection Facts
            "A simple 'Hi' can bridge any distance.",
            "Everyone appreciates knowing someone thought of them.",
            "Don't overthink it – just check in!",
            "Small connections build strong bonds over time.",
            "Reaching out often feels harder than it is.",
            "Curiosity is the spark of connection. Ask how someone's doing.",
            "We all live in our own universes; a quick message is a visit."
        ]
        
        if !viewModel.personStore.people.isEmpty {
            perspectives.insert("Your list: \(viewModel.personStore.people.count) connections.", at: 0)
            // Add perspective based on list size
            if viewModel.personStore.people.count > 10 {
                perspectives.append("That's a solid network you're nurturing!")
            }
        }
        
        // Variations for spontaneous suggestion
        if let suggestion = viewModel.spontaneousSuggestion {
             perspectives.append("Consider reaching out to \(suggestion.name).")
             perspectives.append("What's \(suggestion.name) been up to? Send a quick hello!")
             perspectives.append("Maybe see how \(suggestion.name)'s week is going?")
             // Add more variations if desired
         }
        
        return perspectives
    }

    var body: some View {
        VStack(alignment: .center) {
             // Remove commented-out Title
             
             // Display the dynamic text with Serif font
             Text(currentPerspective)
                .font(.system(.headline, design: .serif))
                 .foregroundColor(AppColor.text)
                 .frame(maxWidth: .infinity, alignment: .center)
                 .multilineTextAlignment(.center)
                 .transition(.opacity.animation(.easeInOut))
                 .id(currentPerspective) // Ensure transition animates when text changes
         }
         .padding(.vertical, 8) // Add slight vertical padding inside the card
         .frame(minHeight: 70) // Increase min height slightly for font
         .onAppear {
             // Generate suggestion if needed (ensure this logic is in ViewModel)
             // viewModel.generateSpontaneousSuggestionIfNeeded()
             
             // Set initial perspective & start cycling
             cyclePerspective()
             // Optional: Add a timer to cycle automatically
             // Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in cyclePerspective() }
         }
    }
    
    // Function to pick a new perspective
    private func cyclePerspective() {
        let perspectives = generatePerspectives()
        if perspectives.isEmpty { 
            currentPerspective = "Add people to begin tracking connections."
            return
        }
        
        // Simple random selection (avoid showing the same one twice in a row if possible)
        var newPerspective = perspectives.randomElement() ?? perspectives[0]
        while newPerspective == currentPerspective && perspectives.count > 1 {
             newPerspective = perspectives.randomElement() ?? perspectives[0]
        }
        currentPerspective = newPerspective
    }
}

#Preview {
     let previewViewModel = LienViewModel()
     previewViewModel.personStore.people = [Person(name: "Preview Person 1", relationshipType: .friend, meetFrequency: .monthly)]
     previewViewModel.spontaneousSuggestion = Person(name: "Suggested Friend", relationshipType: .friend, meetFrequency: .monthly)
     
     return PerspectiveView(viewModel: previewViewModel)
         .modifier(CardStyle())
         .padding()
} 