//
//  RootView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-23.
//

import SwiftUI
import Clerk

struct RootView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(Clerk.self) private var clerk // Needed to pass down if SignIn/Up view needs it

    var body: some View {
        switch appStateManager.navigationState {
        case .loading:
            DSProgressScreen() // Show loading spinner
        case .needsAuth:
             // Replace with your actual combined Sign In / Sign Up view
             // This view will use Clerk SDK components/functions
            SignUpOrSignInView()
                 .environment(clerk) // Pass Clerk instance if needed by SignIn/Up view
        case .needsProfileCompletion:
            CompleteUserProfileView()
                // Pass AppStateManager if needed for signaling completion
                 .environmentObject(appStateManager)
        case .authenticated:
            // Replace with your main authenticated app view (e.g., TabView)
            TabSelection()
                // Pass AppStateManager if main view needs profile data
                 .environmentObject(appStateManager)
        case .error(let message):
            // Simple error view
            VStack {
                 Text("An Error Occurred")
                     .font(.title)
                 Text(message)
                     .foregroundStyle(.red)
                     .padding()
                 Button("Retry Load?") { // Example retry
                     Task { await appStateManager.userIsAuthenticated() }
                 }
            }
        }
    }
}
