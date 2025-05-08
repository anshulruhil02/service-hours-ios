//
//  SubmissionFormView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import SwiftUI
import os.log

struct SubmissionFormView: View {
    @State private var orgName: String = ""
    @State private var hoursString: String = "" // Collect hours as String for flexible input
    @State private var submissionDate: Date = Date() // Default to today
    @State private var description: String = ""
    // State for UI feedback
    @State private var isLoading: Bool = false
    @State private var submissionStatusMessage: String?
    @State private var isError: Bool = false
    @Environment(\.dismiss) var dismiss
    
    // API Service instance (consider injecting later)
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubmissionFormView")
    
    // Formatter for converting Date to ISO8601 String
    private var isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Matches format like 2023-10-27T10:15:30.123Z
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Submission details") {
                    TextField("Organization name", text: $orgName)
                    
                    TextField("Hours completed", text: $hoursString)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date Completed", selection: $submissionDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                    
                    VStack(alignment: .leading) {
                        Text("Description (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 100) // Set a reasonable height
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    }
                }
                
                if let statusMessage = submissionStatusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(isError ? .red : .green)
                        .padding(.vertical, 5)
                }
                
                Section {
                    Button {
                        Task { await  submitForm() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Submit Hours")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Log New Hours")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    func isFormValid() -> Bool {
        guard !orgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !hoursString.isEmpty else { return false }
        guard let hours = Double(hoursString), hours > 0 else { return false }
        
        return true
    }
    
    private func submitForm() async {
        guard isFormValid() else {
            submissionStatusMessage = "Please fill in Organization and valid positive Hours."
            isError = true
            return
        }
        
        guard let hours = Double(hoursString) else {
            isError = true
            submissionStatusMessage = "Please fill in valid hours"
            return
        }
        
        isLoading = true
        isError = false
        print("Date format before transformation \(submissionDate)")
        let dateString = isoDateFormatter.string(from: submissionDate)
        
        let submissionDTO = CreateSubmissionDto(
            orgName: orgName,
            hours: hours,
            submissionDate: dateString,
            description: description.isEmpty ? nil : description
        )
        
        print("Date being sent to backend: \(dateString)")
        do {
            let createSubmission = try await apiService.submitHours(submissionData: submissionDTO)
            
            logger.info("Submission successful! ID: \(createSubmission.id)")
            submissionStatusMessage = "Hours submitted successfully!"
            isError = false
            
            clearForm()
            dismiss()
        } catch {
            logger.error("Submission failed: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized: submissionStatusMessage = "Authentication error. Please sign out and try again."
                case .serverError(_, let msg): submissionStatusMessage = "Server error: \(msg ?? "Please try again.")"
                case .requestFailed: submissionStatusMessage = "Network error. Please check connection."
                default: submissionStatusMessage = "Could not submit hours. Please try again."
                }
            } else {
                submissionStatusMessage = "An unexpected error occurred."
            }
            isError = true
            dump(error)
        }
    }
    
    private func clearForm() {
        orgName = ""
        hoursString = ""
        submissionDate = Date() // Reset to today
        description = ""
    }
}

#Preview {
    SubmissionFormView()
}

