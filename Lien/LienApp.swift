//
//  LienApp.swift
//  Lien
//
//  Created by Jimi on 16/04/2025.
//

import SwiftUI

@main
struct LienApp: App {
    // State to control splash screen visibility
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            // Show SplashView initially, controlled by showSplash
            if showSplash {
                 // Pass binding to the state variable
                 SplashView(isActive: $showSplash.inverted) // Pass inverted binding
            } else {
                 // Once splash is done (showSplash becomes false), show ContentView
                 ContentView()
            }
        }
    }
}

// Helper extension for inverted binding (optional but cleaner)
extension Binding where Value == Bool {
    var inverted: Binding<Bool> {
        Binding<Bool>(
            get: { !self.wrappedValue },
            set: { self.wrappedValue = !$0 }
        )
    }
}
