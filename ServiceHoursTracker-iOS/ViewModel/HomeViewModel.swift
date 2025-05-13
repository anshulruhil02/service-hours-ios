//
//  HomeViewModel.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import Foundation
import Combine
import os.log
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var submissions: [SubmissionResponse] = []
    @Published var completeSubmissions: [SubmissionResponse] = []
    @Published var incompleteSubmissions: [SubmissionResponse] = []
    @Published var showingSubmitSheet: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var exportPDF = false
    
    
    // --- NEW Published Properties for PDF ---
    @Published var pdfReportData: Data? = nil // Holds the fetched PDF data
    @Published var showingShareSheet: Bool = false // Controls presentation of ShareLink's sheet
    @Published var isGeneratingReport: Bool = false // Specific loading state for report
    @Published var reportError: String? = nil
    @Published var pdfReportFileUrl: URL? = nil
    
    // Add a new published property for the user profile
    @Published var userProfile: UserProfile?
    @Published var isLoadingProfile: Bool = false
    @Published var profileError: String?

    
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeViewModel")
    
    func fetchUserProfile() async {
        guard !isLoadingProfile else { return }
        
        isLoadingProfile = true
        profileError = nil
        
        do {
            let fetchedProfile = try await apiService.fetchUserProfile()
            self.userProfile = fetchedProfile
            logger.info("Successfully fetched user profile for \(fetchedProfile.name)")
        } catch is CancellationError {
            logger.info("Fetch user profile task was cancelled. This is normal.")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                profileError = "Authentication error. Please sign out and sign in again."
            case .noActiveSession, .tokenUnavailable:
                profileError = "Not logged in or session invalid."
                // ... handle other error cases ...
            default:
                profileError = "Failed to load user profile. Please try again."
            }
            logger.error("API error fetching user profile: \(error.localizedDescription)")
        } catch {
            logger.error("Unexpected error fetching user profile: \(error.localizedDescription)")
            profileError = "An unexpected error occurred while loading user profile."
        }
        
        isLoadingProfile = false
    }
    
    
    func fetchUserSubmissions() async {
        do {
            errorMessage = nil
            print("inside the viewModel's fetch function")
            let fetchedSubmissions = try await apiService.fetchSubmissions()
            self.submissions = fetchedSubmissions
            self.completeSubmissions = submissions.filter { $0.status == "SUBMITTED" }
            self.incompleteSubmissions = submissions.filter { $0.status == "DRAFT" }
            print("Complete submissions: \(completeSubmissions)")
            print("Incomplete submissions: \(incompleteSubmissions)")
            logger.info("Successfully fetched \(fetchedSubmissions.count) submissions from API.")
        } catch is CancellationError { // <-- CATCH CANCELLATION ERROR
            logger.info("Fetch submissions task was cancelled (e.g., tab switched). This is normal.")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Authentication error. Please sign out and sign in again."
            case .noActiveSession, .tokenUnavailable:
                errorMessage = "Not logged in or session invalid."
            case .serverError(_, let msg):
                errorMessage = "Server error: \(msg ?? "Could not load data.")"
            case .requestFailed:
                errorMessage = "Network error. Please check your connection."
            case .decodingError:
                errorMessage = "Received invalid data from server."
            default:
                errorMessage = "Failed to load submissions. Please try again."
            }
            dump(error)
        } catch {
            logger.error("Unexpected error fetching submissions: \(error)")
            errorMessage = "An unexpected error occurred while loading submissions."
            dump(error)
        }
        
        isLoading = false
    }
    
    func generateAndPreparePdfReport() async {
            guard !isGeneratingReport else { return }
            
            logger.info("Generating PDF report...")
            isGeneratingReport = true
            reportError = nil
            pdfReportFileUrl = nil // Clear previous URL

            do {
                let fetchedPdfData = try await apiService.downloadPdfReport()
                
                // --- Save Data to a Temporary File ---
                let tempDir = FileManager.default.temporaryDirectory
                // Use a unique name, or a consistent one if you want to overwrite
                let fileName = "CommunityHoursReport-\(UUID().uuidString).pdf"
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try fetchedPdfData.write(to: fileURL) // Write the data to the file
                
                self.pdfReportFileUrl = fileURL // Store the URL
                // --- End Save Data ---
                
                self.showingShareSheet = true // Trigger the share sheet in the View
                logger.info("PDF report saved to temporary file: \(fileURL.path) and ready for sharing.")

            } catch let error as APIError {
                logger.error("Failed to generate PDF report: \(error.localizedDescription)")
                // ... (your existing error handling for APIError) ...
                switch error {
                    case .unauthorized: reportError = "Authentication error..."
                    default: reportError = "Could not generate report..."
                }
                dump(error)
            } catch { // Catch errors from file writing or other unexpected errors
                logger.error("Unexpected error generating PDF report or saving to file: \(error.localizedDescription)")
                reportError = "An unexpected error occurred while preparing the report."
                dump(error)
            }
            isGeneratingReport = false
        }
}
