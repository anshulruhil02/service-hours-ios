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
        // Use List for grouped sections, provides scrolling automatically
        List {
            // Section for core submission details
            Section("Submission Details") {
                DetailRow(label: "Organization", value: submission.orgName)
                DetailRow(label: "Hours Submitted", value: String(format: "%.1f", submission.hours)) // Format hours
                DetailRow(label: "Date Completed", value: submission.submissionDate, formatter: Self.submissionDateFormatter)
                
//                // Display Status with color coding
//                HStack {
//                    Text("Status")
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    Text(submission.status.capitalized)
//                        .font(.headline)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 3)
//                        .background(statusColor(submission.status).opacity(0.15))
//                        .foregroundColor(statusColor(submission.status))
//                        .cornerRadius(5)
//                }
            }
            
            // Section for the description, only shown if it exists
            if let description = submission.description, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .foregroundStyle(.primary) // Use primary color for readability
                }
            }
            
            // Section for proof (implement later when file uploads are done)
            // Section("Proof") {
            //     if let proofUrl = submission.proofUrl, !proofUrl.isEmpty {
            //         // Display link or thumbnail later
            //         Link("View Proof", destination: URL(string: proofUrl)!) // Basic link, needs validation
            //     } else {
            //         Text("No proof submitted")
            //             .foregroundStyle(.secondary)
            //     }
            // }
            
            // Section for metadata
            Section("Record Info") {
                 DetailRow(label: "Submitted On", value: submission.createdAt, formatter: Self.timestampFormatter)
                 DetailRow(label: "Last Updated", value: submission.updatedAt, formatter: Self.timestampFormatter)
                 DetailRow(label: "Internal ID", value: submission.id)
                     .font(.caption)
                     .foregroundStyle(.secondary)
            }
            
            Section("Signatures") {
                HStack{
                    Group{
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
                                        .border(Color.secondary) // Add a border
                                case .failure(let error):
                                    // Display error if image loading fails
                                    VStack {
                                        Image(systemName: "photo.fill") // Placeholder icon
                                            .foregroundColor(.orange)
                                        Text("Could not load signature image.")
                                            .font(.caption)
                                        Text(error.localizedDescription)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                @unknown default:
                                    EmptyView() // Handle future cases
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                        } else if let errorMsg = supervisorSignatureError {
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
                    
                    Group{
                        // Conditional UI based on loading state and URL availability
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
                                        .border(Color.secondary) // Add a border
                                case .failure(let error):
                                    // Display error if image loading fails
                                    VStack {
                                        Image(systemName: "photo.fill") // Placeholder icon
                                            .foregroundColor(.orange)
                                        Text("Could not load signature image.")
                                            .font(.caption)
                                        Text(error.localizedDescription)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
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
        .task {
            if supervisorSignatureViewUrl == nil && !supervisorIsLoadingSignature && supervisorSignatureError == nil {
                await loadSupervisorSignatureUrl()
            }
            
            if preApprovedSignatureViewUrl == nil && !preApprovedIsLoadingSignature && preApprovedSignatureError == nil {
                await loadPreApprovedSignatureUrl()
            }
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
}

// --- Reusable Helper View for Label/Value Rows ---
// (Define this once, perhaps in a separate Utilities file, or keep here if only used locally)
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
                .foregroundStyle(.secondary) // Make label slightly less prominent
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing) // Align value text to the right
                .foregroundStyle(.primary) // Ensure value text is clearly visible
        }
    }
}
