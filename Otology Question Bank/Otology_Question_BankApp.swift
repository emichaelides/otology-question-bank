//
//  Otology_Question_BankApp.swift
//  Otology Question Bank
//
//  Created by Elias Michaelides1 on 2/19/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct Otology_Question_BankApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
