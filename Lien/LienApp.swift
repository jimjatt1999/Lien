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
    
    // Keep existing StateObjects if any (e.g., for viewModel)
    @StateObject var viewModel = LienViewModel() 
    
    // Environment variable to detect scene phase
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            // Show SplashView initially, controlled by showSplash
            if showSplash {
                 // Pass binding to the state variable
                 SplashView(isActive: $showSplash.inverted) // Pass inverted binding
            } else {
                 // Once splash is done (showSplash becomes false), show ContentView
                 ContentView(viewModel: viewModel) // Pass viewModel if needed by ContentView
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                print("App entering background. Scheduling connection reminders...")
                // Check authorization status before scheduling
                NotificationManager.shared.checkAuthorizationStatus { status in
                    if status == .authorized {
                        NotificationManager.shared.scheduleConnectionReminders(entries: viewModel.connectionGoalEntries)
                    } else {
                        print("Notification permission not granted. Skipping reminder scheduling.")
                    }
                }
            }
            // Optional: You might also want to schedule when becoming active
            // else if newPhase == .active {
            //     // Potentially refresh or schedule here too?
            // }
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
