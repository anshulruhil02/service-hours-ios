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
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
     @EnvironmentObject var appState: AppStateManager

    // Instance of your API service
    // For better testability later, consider injecting this via initializer or environment
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CompleteUserProfileView")

    var body: some View {
        NavigationView {
            ZStack {
                DSColor.backgroundPrimary.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Complete Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(DSColor.textPrimary)
                    
                    Text("Please provide the following required information to continue:")
                        .font(.subheadline)
                        .foregroundColor(DSColor.textSecondary)
                    
                    Group {
                        TextField("OEN Number", text: $oen)
                            .keyboardType(.numberPad)
                        
                        TextField("School ID", text: $schoolId)
                    }
                    .padding()
                    .background(DSColor.backgroundSecondary) // Using backgroundSecondary as a surface for inputs
                    .foregroundColor(DSColor.textPrimary) // For the typed text
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DSColor.border, lineWidth: 1) // Use DS border color
                    )
                    
                    // Display error messages
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(DSColor.statusError)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    Spacer() // Push button to bottom
                    
                    Button {
                        Task { await submitProfile() }
                    }  label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(DSColor.textOnAccent)
                            } else {
                                Text("Submit Profile")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .frame(height: 30) // Ensure a consistent height for the button's content area
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DSColor.accent)
                    .foregroundColor(DSColor.textOnAccent)
                    .controlSize(.large)
                    .cornerRadius(8)
                    .disabled(isLoading || oen.isEmpty || schoolId.isEmpty)
                    .opacity((isLoading || oen.isEmpty || schoolId.isEmpty) ? 0.6 : 1.0)
                    
                }
                .padding()
                .navigationTitle("Profile Setup")
                .navigationBarTitleDisplayMode(.inline)
            }
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
