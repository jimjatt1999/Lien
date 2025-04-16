import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool // Changed to Binding
    @State private var opacity = 0.0   // Controls fade-in animation

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

                // Definitions
                VStack(alignment: .center, spacing: 8) {
                    Text("lien: (nm) link; connection; bond")
                        .font(.system(.headline, design: .serif))
                        .italic()
                        .foregroundColor(AppColor.secondaryText)
                    
                    Text("A reminder of the threads that connect us.")
                         .font(.system(.subheadline, design: .rounded))
                         .foregroundColor(AppColor.secondaryText)
                }
                .opacity(opacity) // Apply fade-in

                Spacer() // Push content towards center
                Spacer() // Add more space at the bottom if desired
            }
            .padding()
        }
        .onAppear {
            // Start fade-in animation
            withAnimation(.easeIn(duration: 1.5)) {
                self.opacity = 1.0
            }
            
            // Schedule transition to main content after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // Adjust delay as needed (e.g., 2.5 seconds)
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