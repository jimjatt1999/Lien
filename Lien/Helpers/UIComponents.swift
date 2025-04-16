import SwiftUI

// MARK: - Colors
struct AppColor {
    static let primaryBackground = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let accent = Color.primary
    
    // Explicit Black & White (can be useful for specific elements)
    static let black = Color.black
    static let white = Color.white
    
    // Custom shades for contact avatars
    static let avatarColors: [Color] = [
        .gray, .brown, .indigo, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan
    ]
    
    static func avatarColor(for id: UUID) -> Color {
        let colorIndex = abs(id.hashValue) % avatarColors.count
        return avatarColors[colorIndex]
    }
}

// MARK: - Common Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppColor.accent)
            .foregroundColor(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppColor.cardBackground)
            .foregroundColor(AppColor.text)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColor.accent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let person: Person
    let size: CGFloat
    
    var body: some View {
        if let displayImage = person.displayImage {
            displayImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppColor.avatarColor(for: person.id))
                .frame(width: size, height: size)
                .overlay(
                    Text(person.initials)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Time Visualization
struct TimeRemainingView: View {
    let title: String
    let count: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.text)
                
                Text("of \(total)")
                    .font(.footnote)
                    .foregroundColor(AppColor.secondaryText)
            }
            
            ProgressView(value: Double(count), total: Double(total))
                .tint(AppColor.accent)
                .frame(height: 6)
                .padding(.top, 2)
        }
    }
}

// MARK: - Custom TextField
struct LienTextField: View {
    var title: String
    var text: Binding<String>
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
            
            TextField(placeholder, text: text)
                .padding()
                .background(AppColor.cardBackground)
                .cornerRadius(8)
                .keyboardType(keyboardType)
        }
    }
} 