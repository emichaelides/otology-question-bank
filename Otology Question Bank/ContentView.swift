//
//  ContentView.swift
//  Otology Question Bank
//
//  Created by Elias Michaelides1 on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var engine = QuizEngine()

    var body: some View {
        TabView {
            QuizView()
                .tabItem { Label("Quiz", systemImage: "questionmark.circle.fill") }
                .environmentObject(engine)

            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .environmentObject(engine)

            BrowseView()
                .tabItem { Label("Browse", systemImage: "books.vertical.fill") }
                .environmentObject(engine)
        }
    }
}

#Preview {
    ContentView()
}
