//
//  AppStateManager.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-23.
//

import SwiftUI
import Combine // Needed for ObservableObject

// Enum to represent the different states of the app's main view
enum AppNavigationState: Equatable {
    case loading // Initial loading or profile fetch
    case needsAuth // User needs to sign in or sign up
    case needsProfileCompletion // User logged in, but profile incomplete
    case authenticated // User logged in and profile complete
    case error(String) // An error occurred (e.g., during profile fetch)
    
    static func == (lhs: AppNavigationState, rhs: AppNavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.needsAuth, .needsAuth):
            return true
        case (.needsProfileCompletion, .needsProfileCompletion):
            return true
        case (.authenticated, .authenticated):
            return true
        default:
            return false
        }
    }
}

// ObservableObject to manage the application's navigation state beyond basic auth
@MainActor // Ensure changes are published on the main thread
class AppStateManager: ObservableObject {
    
    // Published properties will trigger UI updates when they change
    @Published var navigationState: AppNavigationState = .loading
    @Published var userProfile: UserProfile? = nil // Store the fetched profile
    
    private let apiService = APIService() // Instance of your API service
    
    // Function to be called when Clerk confirms user is authenticated
    func userIsAuthenticated() async {
        navigationState = .loading // Show loading while fetching profile
        userProfile = nil // Clear previous profile if any
        
        do {
            let fetchedProfile = try await apiService.fetchUserProfile()
            self.userProfile = fetchedProfile
            
            // Check if profile is complete (adjust logic based on your requirements)
            if fetchedProfile.oen?.isEmpty ?? true || fetchedProfile.schoolId?.isEmpty ?? true {
                navigationState = .needsProfileCompletion
            } else {
                navigationState = .authenticated
            }
        } catch let error as APIError {
            // Handle specific errors, e.g., unauthorized might mean session issue
            if case .unauthorized = error {
                navigationState = .needsAuth // Force back to auth if token failed
            } else {
                navigationState = .error("Failed to load profile: \(error.localizedDescription)")
            }
        } catch {
            navigationState = .error("An unexpected error occurred.")
        }
    }
    
    // Function called by CompleteUserProfileView upon successful update
    func profileCompletionSuccessful() {
        // Re-fetch profile to be sure or just assume complete and navigate
        // For simplicity, just navigate:
        navigationState = .authenticated
        // Consider re-fetching profile in background if needed
    }
    
    // Function to reset state on sign out
    func userSignedOut() {
        navigationState = .needsAuth
        userProfile = nil
    }
}
