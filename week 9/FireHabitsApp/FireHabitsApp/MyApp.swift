//
//  FireHabitsApp.swift
//  App entry point: starts Firebase and shows the first screen.
//

import SwiftUI
import FirebaseCore

@main
struct FireHabitsApp: App {

    init() {
        // Connects the app to Firebase project
        // (reads the GoogleService-Info.plist file). Must run first.
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
