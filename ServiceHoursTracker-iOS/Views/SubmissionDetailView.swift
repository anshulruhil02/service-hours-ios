//
//  SubmissionDetailView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-05.
//


import SwiftUI
import os.log // Optional for logging

struct SubmissionDetailView: View {
    // Input property: The submission whose details we want to display
    let submission: SubmissionResponse
    private let apiService = APIService()
    
    // States for the Supervisor signature URL and loading status
    @State private var supervisorSignatureViewUrl: URL? = nil
    @State private var supervisorIsLoadingSignature: Bool = false
    @State private var supervisorSignatureError: String? = nil
    
    // States for the Pre Approved signature URL and loading status
    @State private var preApprovedSignatureViewUrl: URL? = nil
    @State private var preApprovedIsLoadingSignature: Bool = false
    @State private var preApprovedSignatureError: String? = nil
    
    // New states for delete functionality
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteError: String? = nil
    @Environment(\.dismiss) var dismiss
    
    
    // Logger instance (optional)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubmissionDetailView")
    
    // Formatter for displaying the main submission date clearly
    private static var submissionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // e.g., May 5, 2025
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Formatter for displaying timestamps (created/updated)
    private static var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., May 5, 2025
        formatter.timeStyle = .short // e.g., 6:30 PM
        return formatter
    }()
    
    var body: some View {
        ZStack {
            DSColor.backgroundPrimary.ignoresSafeArea()
            List {
                // Section for core submission details
                Section("Submission Details") {
                    DetailRow(label: "Organization", value: submission.orgName ?? "No Org name")
                    DetailRow(label: "Hours Submitted", value: String(format: "%.1f", submission.hours ?? 0)) // Format hours
                    DetailRow(label: "Date Completed", value: submission.submissionDate, formatter: Self.submissionDateFormatter)
                    DetailRow(label: "Telephone", value: String(format: "%.1f", submission.telephone ?? 0))
                    DetailRow(label: "Supervisor name", value: submission.supervisorName ?? "No supervisor name")
                }
                
                // Section for the description, only shown if it exists
                if let description = submission.description, !description.isEmpty {
                    Section("Description") {
                        Text(description)
                            .foregroundStyle(.primary) // Use primary color for readability
                    }
                }
                
                // Section for metadata
                Section("Record Info") {
                    DetailRow(label: "Submitted On", value: submission.createdAt, formatter: Self.timestampFormatter)
                    DetailRow(label: "Last Updated", value: submission.updatedAt, formatter: Self.timestampFormatter)
                    HStack {
                        Text("Internal ID")
                            .foregroundColor(DSColor.textSecondary)
                        Spacer()
                        Text(submission.id)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(DSColor.textSecondary) // Make value secondary as well
                    }
                    .font(.caption)
                }
                
                Section("Signatures") {
                    VStack(alignment: .leading) {
                        Text("Supervisor Signature")
                            .font(.headline) // Consider DSFont.headline
                            .foregroundColor(DSColor.textPrimary)
                            .padding(.bottom, 2)
                        // Conditional UI based on loading state and URL availability
                        if supervisorIsLoadingSignature {
                            HStack { // Center the ProgressView
                                Spacer()
                                ProgressView("Loading Signature...")
                                Spacer()
                            }
                            .frame(height: 150) // Give space while loading
                        } else if let url = supervisorSignatureViewUrl {
                            // Use AsyncImage to load from the temporary S3 URL
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView() // Placeholder while image downloads
                                        .frame(height: 150)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150) // Limit display height
                                        .border(DSColor.border) // Add a border
                                        .background(.white)
                                case .failure(let error):
                                    VStack {
                                        Image(systemName: "photo.fill")
                                            .foregroundColor(DSColor.statusWarning) // Use DS warning color
                                        Text("Could not load signature.")
                                            .font(.caption).foregroundColor(DSColor.textSecondary)
                                        Text(error.localizedDescription)
                                            .font(.caption2).foregroundColor(DSColor.textSecondary)
                                    }
                                    .frame(height: 150)
                                @unknown default:
                                    EmptyView() // Handle future cases
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                        } else if let errorMsg = supervisorSignatureError {
                            // Display error if fetching the URL failed
                            Text("Error loading signature: \(errorMsg)")
                                .font(.caption).foregroundColor(DSColor.statusError)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        }
                        else {
                            // Display if no signature URL was stored or returned by backend
                            Text("No signature attached.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        }
                    }
                    
                    VStack(alignment: .leading) { // Added VStack for title + content
                        Text("Pre-Approved Signature")
                            .font(.headline) // Consider DSFont.headline
                            .foregroundColor(DSColor.textPrimary)
                            .padding(.bottom, 2)
                        if preApprovedIsLoadingSignature {
                            HStack { // Center the ProgressView
                                Spacer()
                                ProgressView("Loading Signature...")
                                Spacer()
                            }
                            .frame(height: 150) // Give space while loading
                        } else if let url = preApprovedSignatureViewUrl {
                            // Use AsyncImage to load from the temporary S3 URL
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView() // Placeholder while image downloads
                                        .frame(height: 150)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150) // Limit display height
                                        .border(DSColor.border) // Add a border
                                        .background(.white)
                                case .failure(let error):
                                    // Display error if image loading fails
                                    VStack {
                                        Image(systemName: "photo.fill")
                                            .foregroundColor(DSColor.statusWarning) // Use DS warning color
                                        Text("Could not load signature.")
                                            .font(.caption).foregroundColor(DSColor.textSecondary)
                                        Text(error.localizedDescription)
                                            .font(.caption2).foregroundColor(DSColor.textSecondary)
                                    }
                                @unknown default:
                                    EmptyView() // Handle future cases
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                        } else if let errorMsg = preApprovedSignatureError {
                            // Display error if fetching the URL failed
                            Text("Error loading signature: \(errorMsg)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        }
                        else {
                            // Display if no signature URL was stored or returned by backend
                            Text("No signature attached.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        }
                    }
                }
            } // End
            
        }
        .navigationTitle("Submission Details") // Title for this screen
        .navigationBarTitleDisplayMode(.inline) // Keep title small
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                        }
                    }
                    .foregroundColor(DSColor.statusError)
                }
                .disabled(isDeleting)
            }
        }
        .task {
            if supervisorSignatureViewUrl == nil && !supervisorIsLoadingSignature && supervisorSignatureError == nil {
                await loadSupervisorSignatureUrl()
            }
            
            if preApprovedSignatureViewUrl == nil && !preApprovedIsLoadingSignature && preApprovedSignatureError == nil {
                await loadPreApprovedSignatureUrl()
            }
        }
        .alert("Delete Submission", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSubmission()
                }
            }
        } message: {
            Text("Are you sure you want to delete this submission? This action cannot be undone.")
        }
        
    }
    
    func loadSupervisorSignatureUrl() async {
        supervisorIsLoadingSignature = true
        supervisorSignatureError = nil
        logger.info("Fetching signature view URL for submission \(submission.id)")
        
        do {
            let result = try await apiService.getSupervisorSignatureViewUrl(submissionId: submission.id)
            print("Dignature fetching result: \(String(describing: result))")
            supervisorSignatureViewUrl = result // This might be nil if backend returns null
            if supervisorSignatureViewUrl == nil {
                logger.info("Backend confirmed no viewable signature URL for submission \(submission.id)")
            } else {
                logger.info("Successfully got signature view URL.")
            }
        } catch let error as APIError {
            logger.error("Failed to fetch signature view URL: \(error)")
            supervisorSignatureError = "Could not load signature (\(error.localizedDescription))."
            dump(error)
        } catch {
            logger.error("Unexpected error fetching signature view URL: \(error)")
            supervisorSignatureError = "An unexpected error occurred."
            dump(error)
        }
        
        supervisorIsLoadingSignature = false
    }
    
    func loadPreApprovedSignatureUrl() async {
        preApprovedIsLoadingSignature = true
        preApprovedSignatureError = nil
        logger.info("Fetching signature view URL for submission \(submission.id)")
        
        do {
            let result = try await apiService.getPreApprovedSignatureViewUrl(submissionId: submission.id)
            print("Dignature fetching result: \(String(describing: result))")
            preApprovedSignatureViewUrl = result // This might be nil if backend returns null
            if preApprovedSignatureViewUrl == nil {
                logger.info("Backend confirmed no viewable signature URL for submission \(submission.id)")
            } else {
                logger.info("Successfully got signature view URL.")
            }
        } catch let error as APIError {
            logger.error("Failed to fetch signature view URL: \(error)")
            preApprovedSignatureError = "Could not load signature (\(error.localizedDescription))."
            dump(error)
        } catch {
            logger.error("Unexpected error fetching signature view URL: \(error)")
            preApprovedSignatureError = "An unexpected error occurred."
            dump(error)
        }
        
        preApprovedIsLoadingSignature = false
    }
    
    private func deleteSubmission() async {
        isDeleting = true
        deleteError = nil
        
        do {
            try await apiService.deleteSubmission(submissionId: submission.id)
            logger.info("Successfully deleted submission \(submission.id)")
            
            // Dismiss the view after successful deletion
            await MainActor.run {
                dismiss()
            }
        } catch let error as APIError {
            logger.error("Failed to delete submission: \(error)")
            await MainActor.run {
                switch error {
                case .unauthorized:
                    deleteError = "Authentication error. Please sign in again."
                case .serverError(_, let msg):
                    deleteError = msg ?? "Server error occurred."
                case .requestFailed:
                    deleteError = "Network error. Please check your connection."
                default:
                    deleteError = "Could not delete submission."
                }
            }
        } catch {
            logger.error("Unexpected error deleting submission: \(error)")
            await MainActor.run {
                deleteError = "An unexpected error occurred."
            }
        }
        
        isDeleting = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    // Initializer for String values
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    // Overload Initializer for Date values
    init(label: String, value: Date, formatter: DateFormatter) {
        self.label = label
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(DSColor.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(DSColor.textPrimary)
        }
    }
}
