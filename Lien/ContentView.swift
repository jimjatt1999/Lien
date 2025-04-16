//
//  ContentView.swift
//  Lien
//
//  Created by Jimi on 16/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = LienViewModel()
    
    var body: some View {
        if viewModel.isOnboarded {
            MainTabView(viewModel: viewModel)
        } else {
            OnboardingView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
