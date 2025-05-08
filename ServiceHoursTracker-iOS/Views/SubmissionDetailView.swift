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
        }
        .navigationTitle("Submission Details") // Title for this screen
        .navigationBarTitleDisplayMode(.inline) // Keep title small
    }
    
     // Helper function to determine status color (copied from SubmissionRow)
//     func statusColor(_ status: String) -> Color {
//         switch status.lowercased() {
//             case "approved": return .green
//             case "rejected": return .red
//             default: return .orange // pending
//         }
//     }
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
