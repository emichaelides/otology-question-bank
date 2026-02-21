//
//  Otology_Question_BankApp.swift
//  Otology Question Bank
//
//  Created by Elias Michaelides1 on 2/19/26.
//

import SwiftUI
import FirebaseCore

@main
struct Otology_Question_BankApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
