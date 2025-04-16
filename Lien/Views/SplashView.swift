import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool // Changed to Binding
    @State private var opacity = 0.0   // Controls fade-in animation
    @State private var currentQuote: String = "" // State for the quote

    // Add the quotes array here
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
        // Use a ZStack for layering background and content
        ZStack {
            // Background - Use the correct color from AppColor
            AppColor.primaryBackground // Use the defined primary background
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer() // Push content towards center

                // App Name
                Text("Lien.")
                    .font(.system(size: 70, weight: .bold, design: .serif)) // Stylish font
                    .foregroundColor(AppColor.text) // Use app's text color

                // Definitions & Quote VStack
                VStack(alignment: .center, spacing: 15) { // Increased spacing
                    Text("lien: (nm) link; connection; bond")
                        .font(.system(.headline, design: .serif))
                        .italic()
                        .foregroundColor(AppColor.secondaryText)
                    
                    Text("A reminder of the threads that connect us.")
                         .font(.system(.subheadline, design: .rounded))
                         .foregroundColor(AppColor.secondaryText)
                    
                    // Display the selected quote
                    if !currentQuote.isEmpty {
                        let quoteParts = currentQuote.components(separatedBy: " - ")
                        let quoteText = quoteParts.first ?? currentQuote
                        let authorText = quoteParts.count > 1 ? "- \(quoteParts.last!)" : nil
                        
                        VStack(spacing: 5) {
                            Text("\"\(quoteText)\"")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                            
                            if let author = authorText {
                                Text(author)
                                    .font(.system(.caption, design: .serif))
                                    .foregroundColor(AppColor.secondaryText)
                            }
                        }
                        .padding(.top, 10) // Add space above quote
                    }
                }
                .opacity(opacity) // Apply fade-in to the whole block

                Spacer() // Push content towards center
                Spacer() // Add more space at the bottom if desired
            }
            .padding()
        }
        .onAppear {
            // Select a random quote
            self.currentQuote = quotes.randomElement() ?? quotes[0]
            
            // Start fade-in animation
            withAnimation(.easeIn(duration: 1.5)) {
                self.opacity = 1.0
            }
            
            // Schedule transition to main content after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Slightly longer delay? Adjust as needed
                 withAnimation {
                    // This state change should be observed by ContentView to switch views
                    // For now, we just set it. We'll connect it in ContentView next.
                     self.isActive = true 
                 }
            }
        }
        // If you want the SplashView itself to handle switching, you could do this:
        // Replace ZStack with:
        // if isActive {
        //    ContentView() // Or your main TabView container
        // } else {
        //    ZStack { ... content ... }
        // }
        // But it's generally better to let the parent container handle the switch.
    }
}

#Preview {
    // Preview needs a dummy state variable for the binding
    struct PreviewWrapper: View {
        @State private var previewIsActive = false
        var body: some View {
            SplashView(isActive: $previewIsActive)
        }
    }
    return PreviewWrapper()
} 