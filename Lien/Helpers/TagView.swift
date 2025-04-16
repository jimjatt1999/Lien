import SwiftUI

struct TagView: View {
    let title: String
    var isSelected: Bool = false // Optional: for filter indication
    var showDelete: Bool = false
    var onSelect: (() -> Void)? = nil // Make sure this is optional
    var onDelete: (() -> Void)? = nil // Make sure this is optional
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                 .font(.caption)
                 .lineLimit(1)
                 .foregroundColor(isSelected ? .white : AppColor.text)
                 .padding(.leading, 8)
                 .padding(.vertical, 4)
            
            if showDelete {
                 Button {
                     onDelete?()
                 } label: {
                     Image(systemName: "xmark.circle.fill")
                         .font(.caption) // Match font size
                         .foregroundColor(isSelected ? .white.opacity(0.7) : .gray)
                 }
                 .padding(.trailing, 8)
             } else {
                 // Add trailing padding if no delete button
                 Spacer().frame(width: 8)
             }
        }
        .background(isSelected ? AppColor.accent : AppColor.cardBackground.opacity(0.8))
        .cornerRadius(15)
        .onTapGesture {
            // Only trigger select if delete isn't shown or wasn't the primary action
            if !showDelete {
                onSelect?() 
            }
        }
        // Allow taps only if onSelect is provided or it's not deletable?
        .allowsHitTesting(onSelect != nil || !showDelete)
    }
}

#Preview { 
    VStack(spacing: 10) {
        TagView(title: "Simple")
        TagView(title: "Selectable", onSelect: { print("Selected Simple") })
        TagView(title: "Selected State", isSelected: true)
        TagView(title: "Deletable", showDelete: true, onDelete: { print("Deleted Deletable") })
        TagView(title: "Selectable & Deletable", showDelete: true, onSelect: { print("Selected S&D") }, onDelete: { print("Deleted S&D") })
    }
    .padding()
    .background(Color.gray.opacity(0.2))
} 