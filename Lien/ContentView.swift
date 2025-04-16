//
//  ContentView.swift
//  Lien
//
//  Created by Jimi on 16/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LienViewModel()
    @StateObject private var appManager = AppManager()

    var body: some View {
        Group {
            if viewModel.isOnboarded {
                MainTabView(viewModel: viewModel)
            } else {
                OnboardingView(viewModel: viewModel)
            }
        }
        .fontDesign(appManager.appFontDesign.swiftUIFontDesign)
        .environmentObject(appManager)
        .onAppear {
            NotificationManager.shared.requestAuthorization { granted, error in
                if granted {
                    print("Notification permission granted.")
                } else {
                    print("Notification permission denied.")
                    // Optionally, guide user to settings if denied and needed later
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
