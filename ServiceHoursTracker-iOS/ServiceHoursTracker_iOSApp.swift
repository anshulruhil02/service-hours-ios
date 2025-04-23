//
//  ServiceHoursTracker_iOSApp.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-21.
//

import SwiftUI
import Clerk

@main
struct ServiceHoursTracker_iOSApp: App {
    @State var clerk = Clerk.shared
    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.isLoaded {
                    ContentView()
                } else {
                    ProgressView()
                }
            }
            .environment(clerk)
            .task {
                do {
                    print("Attempting to load Clerk...")
                    clerk.configure(publishableKey: "pk_test_bGl2aW5nLWhlcm9uLTk4LmNsZXJrLmFjY291bnRzLmRldiQ")
                    try await clerk.load()
                    print("Clerk loaded successfully.") 
                } catch {
                    print("Error info: \(error)")
                }
            }
        }
    }
}
