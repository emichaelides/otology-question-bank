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
        NavigationStack {
            HomeView()
        }
        .environmentObject(engine)
    }
}

#Preview {
    ContentView()
}
