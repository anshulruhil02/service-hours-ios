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
    @State private var principal: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    
    // Instance of your API service
    // For better testability later, consider injecting this via initializer or environment
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CompleteUserProfileView")
    
    // Form validation
    private var isFormValid: Bool {
        !oen.isEmpty &&
        !schoolId.isEmpty &&
        !principal.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DSColor.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    // Form Card
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            Text("Complete Your Profile")
                                .font(DSTypography.largeTitleThin)
                                .foregroundColor(DSColor.textPrimary)
                            
                            Text("Please provide the following required information to continue:")
                                .font(DSTypography.subheadline)
                                .foregroundColor(DSColor.textSecondary)
                            DSTextField(
                                "OEN Number",
                                text: $oen,
                                leadingImage: Image(systemName: "number"),
                                keyboardType: .numberPad,
                                textContentType: .none
                            )
                            
                            DSTextField(
                                "School Name",
                                text: $schoolId,
                                leadingImage: Image(systemName: "building.2"),
                                textContentType: .organizationName
                            )
                            
                            DSTextField(
                                "Principal Name",
                                text: $principal,
                                leadingImage: Image(systemName: "person.badge.key"),
                                textContentType: .name
                            )
                            
                            // Custom Date Picker with DS styling
                            HStack(spacing: DSSpacing.md) {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(DSColor.textSecondary)
                                
                                DatePicker(
                                    "Date of Birth",
                                    selection: $dateOfBirth,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .tint(DSColor.accent)
                                .foregroundColor(DSColor.textPrimary)
                            }
                            .padding(DSSpacing.lg)
                            .background(Color.white)
                            .cornerRadius(DSRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.md)
                                    .stroke(DSColor.border.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Error Message
                            if let errorMessage {
                                HStack(spacing: DSSpacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DSColor.statusError)
                                        .font(.caption)
                                    
                                    Text(errorMessage)
                                        .foregroundColor(DSColor.statusError)
                                        .font(DSTypography.caption)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(DSSpacing.md)
                                .background(DSColor.statusError.opacity(0.1))
                                .cornerRadius(DSRadius.sm)
                            }
                            
                            Spacer(minLength: DSSpacing.lg)
                            
                            // Submit Button
                            DSButton("Complete Profile") {
                                Task { await submitProfile() }
                            }
                            .buttonStyle(.primary)
                            .buttonSize(.large)
                            .fullWidth()
                            .enabled(isFormValid)
                            .loading(isLoading)
                        }
                    }
                    
                    
                }
                .padding(DSSpacing.lg)
                .navigationTitle("Profile Setup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        DSLogo(size: .small, style: .icon, logoName: "logo")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Prevents split view on iPad
    }
    
    // Function to handle profile submission
    func submitProfile() async {
        isLoading = true
        errorMessage = nil
        logger.info("Attempting to submit profile with OEN: \(oen), SchoolID: \(schoolId)")
        
        let dob = AppDateFormatter.isoDateFormatter.string(from: dateOfBirth)
        // Create the DTO to send to the backend
        let profileData = UpdateUserProfileDto(
            oen: oen,
            schoolId: schoolId,
            principal: principal,
            dateOfBirth: dob
        )
        
        do {
            // Call the APIService method to update the profile
            let updatedProfile = try await apiService.updateUserProfile(profileData: profileData)
            logger.info("Profile update successful for user: \(updatedProfile.email)")
            
            // Success - dismiss and update app state
            dismiss()
            appState.profileCompletionSuccessful()
            
        } catch {
            logger.error("Profile update failed: \(error.localizedDescription)")
            
            // Display user-friendly error message
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized:
                    errorMessage = "Authentication error. Please sign out and try again."
                case .serverError(_, let msg):
                    errorMessage = "Server error: \(msg ?? "Unknown error"). Please try again."
                case .requestFailed:
                    errorMessage = "Network error. Please check your connection and try again."
                default:
                    errorMessage = "Could not update profile. Please try again."
                }
            } else {
                errorMessage = "An unexpected error occurred. Please try again."
            }
            
            dump(error)
        }
        
        isLoading = false // Ensure loading state is reset even on error
    }
}

// MARK: - Preview
#Preview {
    CompleteUserProfileView()
        .environmentObject(AppStateManager())
}
