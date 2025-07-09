//
//  ServiceHoursTracker_iOSApp.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-21.
//

import SwiftUI
import Clerk
import os.log


@main
struct ServiceHoursTracker_iOSApp: App {
    @StateObject private var appStateManager = AppStateManager()
    @State var clerk = Clerk.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppRoot")
    
    init() {
        clerk.configure(publishableKey: "pk_test_bGl2aW5nLWhlcm9uLTk4LmNsZXJrLmFjY291bnRzLmRldiQ")
        logger.info("Clerk configured in init.")
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.isLoaded {
                    RootView()
                        .environment(clerk)
                        .environmentObject(appStateManager)
                        .task {
                            if clerk.session == nil {
                                appStateManager.userSignedOut()
                            } else {
                                await appStateManager.userIsAuthenticated()
                            }
                        }
                        .onChange(of: clerk.session) { oldSession, newSession in
                            handleSessionChange(newSession: newSession)
                        }
                } else {
                    ProgressView()
                        .onAppear {
                            logger.debug("ProgressView appeared, Clerk not loaded yet (isLoaded: \(clerk.isLoaded)).")
                        }
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
    
    private func handleSessionChange(newSession: Session?) {
        Task { @MainActor in
            if newSession != nil {
                // User just logged in or session restored
                if appStateManager.navigationState == .needsAuth || appStateManager.userProfile == nil {
                    await appStateManager.userIsAuthenticated()
                } else {
//                    logger.info("Session detected, profile state already handled (\(appStateManager.navigationState)).")
                }
            } else {
                appStateManager.userSignedOut()
            }
        }
    }
}
