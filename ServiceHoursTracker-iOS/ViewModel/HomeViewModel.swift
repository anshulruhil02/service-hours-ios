//
//  HomeViewModel.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import Foundation
import Combine
import os.log

@MainActor
class HomeViewModel: ObservableObject {
    @Published var submissions: [SubmissionResponse] = []
    @Published var completeSubmissions: [SubmissionResponse] = []
    @Published var incompleteSubmissions: [SubmissionResponse] = []
    @Published var showingSubmitSheet: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeViewModel")

    func fetchUserSubmissions() async {
        do {
            print("inside the viewModel's fetch function")
            let fetchedSubmissions = try await apiService.fetchSubmissions()
            self.submissions = fetchedSubmissions
            self.completeSubmissions = submissions.filter { $0.status == "SUBMITTED" }
            self.incompleteSubmissions = submissions.filter { $0.status == "DRAFT" }
            print("Complete submissions: \(completeSubmissions)")
            print("Incomplete submissions: \(incompleteSubmissions)")
            logger.info("Successfully fetched \(fetchedSubmissions.count) submissions from API.")
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Authentication error. Please sign out and sign in again."
                // Potentially trigger sign out via AppStateManager or Clerk directly
                // Example: Task { try? await Clerk.shared.signOut() }
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
}
