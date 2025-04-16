import SwiftUI

struct PersonImageView: View {
    let person: Person
    let size: CGFloat
    
    var body: some View {
        Group {
            if let displayImage = person.displayImage {
                displayImage
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder with initials
                ZStack {
                    // Use the centralized background color function from AppColor
                    Circle()
                        .fill(AppColor.initialsBackgroundColor(for: person.id))
                    
                    Text(person.initials)
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        // Optional: Add a thin border
        // .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

// Add a color palette to AppColor if it doesn't exist
// Example in AppColor.swift:
/*
 struct AppColor {
     static let accent = Color("AccentColor") // Or your primary color
     // ... other colors ...
 
     static let backgroundPalette: [Color] = [
         .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
     ]
 }
 */

#Preview {
    HStack {
        // Example with image (requires a person with image data)
        // let personWithImage = ... 
        // PersonImageView(person: personWithImage, size: 50)
        
        // Example without image
        PersonImageView(person: Person(name: "Jane Doe", relationshipType: .friend, meetFrequency: .monthly), size: 50)
        PersonImageView(person: Person(name: "Alex Smith", relationshipType: .family, meetFrequency: .weekly), size: 40)
    }
} 