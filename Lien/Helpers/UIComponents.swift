import SwiftUI

// MARK: - Colors
struct AppColor {
    static let primaryBackground = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let accent = Color.blue
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    
    // Custom shades for contact avatars
    static let avatarColors: [Color] = [
        .blue, .indigo, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal
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
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(AppColor.secondaryBackground)
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
    let contact: Contact
    let size: CGFloat
    
    var body: some View {
        if let displayImage = contact.displayImage {
            displayImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppColor.avatarColor(for: contact.id))
                .frame(width: size, height: size)
                .overlay(
                    Text(contact.initials)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColor.secondaryText)
            
            HStack {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.text)
                
                Text("of \(total)")
                    .font(.caption)
                    .foregroundColor(AppColor.secondaryText)
            }
            
            ProgressView(value: Double(count), total: Double(total))
                .tint(AppColor.accent)
                .frame(height: 8)
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Tag View
struct TagView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColor.secondaryBackground)
            .foregroundColor(AppColor.text)
            .cornerRadius(8)
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
                .background(AppColor.secondaryBackground)
                .cornerRadius(8)
                .keyboardType(keyboardType)
        }
    }
} 