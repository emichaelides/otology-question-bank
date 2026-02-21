//
//  ContentView.swift
//  Otology Question Bank
//
//  Created by Elias Michaelides1 on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var engine = QuizEngine()
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environmentObject(engine)
        .fullScreenCover(isPresented: Binding(
            get: { authManager.user == nil },
            set: { _ in }
        )) {
            AuthView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
