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
    @Published var path = NavigationPath()
    
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeViewModel")
    
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
        guard !isGeneratingReport else { return } // Prevent multiple calls
        
        logger.info("Generating PDF report...")
        isGeneratingReport = true
        reportError = nil
        pdfReportData = nil // Clear previous data
        
        do {
            let fetchedPdfData = try await apiService.downloadPdfReport()
            self.pdfReportData = fetchedPdfData
            self.showingShareSheet = true // Trigger the share sheet in the View
            logger.info("PDF report data fetched successfully, ready for sharing.")
        } catch let error as APIError {
            logger.error("Failed to generate PDF report: \(error.localizedDescription)")
            switch error {
            case .unauthorized: reportError = "Authentication error. Please sign out and sign in."
            default: reportError = "Could not generate report. Please try again."
            }
            dump(error)
        } catch {
            logger.error("Unexpected error generating PDF report: \(error.localizedDescription)")
            reportError = "An unexpected error occurred."
            dump(error)
        }
        isGeneratingReport = false
    }
}
