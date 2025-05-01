//
//  CompleteUserProfile.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-23.
//

import SwiftUI
import Clerk // Needed for session/token access potentially
import os.log // For logging


struct CompleteUserProfileView: View {
    // State variables to hold user input
    @State private var oen: String = ""
    @State private var schoolId: String = ""
    
    // State for loading indicator and error messages
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Environment object or Binding to signal completion
    // Option 1: Use Environment Dismiss (simpler if presented modally)
    @Environment(\.dismiss) var dismiss
    // Option 2: Use a Binding passed from the parent view
    // @Binding var isOnboardingComplete: Bool
    // Option 3: Use an @EnvironmentObject for app state
     @EnvironmentObject var appState: AppStateManager

    // Instance of your API service
    // For better testability later, consider injecting this via initializer or environment
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CompleteUserProfileView")

    var body: some View {
        NavigationView { // Wrap in NavigationView for a title (optional)
            VStack(alignment: .leading, spacing: 20) {
                Text("Complete Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please provide the following required information to continue:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("OEN Number", text: $oen)
                    .keyboardType(.numberPad) // Use appropriate keyboard
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5))) // Subtle border

                TextField("School ID", text: $schoolId)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                    
                // Display error messages
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }

                Spacer() // Push button to bottom

                Button {
                    Task { await submitProfile() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white) // Make spinner white on blue button
                            .frame(maxWidth: .infinity)
                            .frame(height: 30) // Match button height
                    } else {
                        Text("Submit Profile")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large) // Make button larger
                .disabled(isLoading || oen.isEmpty || schoolId.isEmpty) // Basic validation

            }
            .padding()
            .navigationTitle("Profile Setup") // Optional title
            .navigationBarTitleDisplayMode(.inline) // Optional title display mode
            // Add background color if desired
            // .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // Function to handle profile submission
    func submitProfile() async {
        isLoading = true
        errorMessage = nil
        logger.info("Attempting to submit profile with OEN: \(oen), SchoolID: \(schoolId)")

        // Create the DTO to send to the backend
        let profileData = UpdateUserProfileDto(oen: oen, schoolId: schoolId)

        do {
            // Call the APIService method to update the profile
            let updatedProfile = try await apiService.updateUserProfile(profileData: profileData)
            logger.info("Profile update successful for user: \(updatedProfile.email)")
            
            // --- Profile update successful! ---
            // Now trigger navigation to the main app content area.
            // Choose ONE of the following methods based on your navigation setup:
            
            // Option 1: Dismiss if presented modally
             dismiss()
            
            // Option 2: Update binding passed from parent
            // isOnboardingComplete = true
            
            // Option 3: Update global app state
            appState.profileCompletionSuccessful()

        } catch {
            logger.error("Profile update failed: \(error.localizedDescription)")
            // Display error message to the user
            if let apiError = error as? APIError {
                 switch apiError {
                     case .unauthorized: errorMessage = "Authentication error. Please sign out and try again."
                     case .serverError(_, let msg): errorMessage = "Server error: \(msg ?? "Unknown") Please try again."
                     case .requestFailed: errorMessage = "Network error. Please check connection."
                     default: errorMessage = "Could not update profile (\(apiError)). Please try again."
                 }
            } else {
                 errorMessage = "An unexpected error occurred."
            }
            dump(error)
        }
        
        isLoading = false // Ensure loading state is reset even on error
    }
}
