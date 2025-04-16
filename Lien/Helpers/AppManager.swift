import SwiftUI
import Combine

// --- Font Design Enum --- 
enum AppFontDesign: String, Codable, CaseIterable, Identifiable {
    case standard = "Default"
    case rounded = "Rounded"
    case serif = "Serif"
    case monospaced = "Monospaced"
    
    var id: String { self.rawValue }
    
    var swiftUIFontDesign: Font.Design {
        switch self {
        case .standard: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

// --- Font Size Enum (Example) ---
enum AppFontSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var id: String { self.rawValue }
    
    // Add actual size mapping if needed
    // var size: CGFloat { ... }
}

// --- Font Width Enum (Example) ---
enum AppFontWidth: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard"
    case condensed = "Condensed"
    case expanded = "Expanded"
    
    var id: String { self.rawValue }
    
    // Add actual width mapping if needed
    // var width: Font.Width { ... } 
}

// --- AppManager Class --- 
class AppManager: ObservableObject {
    // Static instance for easy access if needed, though EnvironmentObject is preferred
    // static let shared = AppManager()
    
    @AppStorage("appFontDesign") var appFontDesign: AppFontDesign = .standard // Default to standard
    @AppStorage("appFontSize") var appFontSize: AppFontSize = .medium
    @AppStorage("appFontWidth") var appFontWidth: AppFontWidth = .standard
    // Add other global app settings here if needed
} 