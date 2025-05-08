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
    @State var isSigning: Bool = false
    @State var clearSignature: Bool = false
    @State var signatureImage: UIImage? = nil
    @State var signaturePDF: Data? = nil
    @State var signaturePNGData: Data? = nil

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
            VStack {
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
                
                Section("Supervisor Signature") {
                    VStack(alignment: .center) {
                        ZStack(alignment: isSigning ? .bottomTrailing: .center) {
                            SignatureViewContainer(clearSignature: $clearSignature, signatureImage: $signatureImage, pdfSignature: $signaturePDF, signaturePNGData: $signaturePNGData)
                                .disabled(!isSigning)
                                .frame(height: 197)
                                .frame(maxWidth: .infinity)
                                .background(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor, lineWidth: 3)
                                )
                            if isSigning {
                                Button(action: {
                                    clearSignature = true
                                }, label: {
                                    HStack {
                                        Text("Clear")
                                            .font(.callout)
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 28)
                                    .background(
                                        Capsule()
                                            .fill(.green)
                                    )
                                })
                                .offset(.init(width: -12, height: -12))
                            } else {
                                Button(action: {
                                    isSigning = true
                                }, label: {
                                    VStack(alignment: .center, spacing: 0) {
                                        Image(systemName: "pencil")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 20, height: 20)
                                            .padding(8)
                                        Text("Sign here")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                })
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 3)
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
                        Task { await submitForm() }
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
        
        // Ensure hours conversion is safe
        guard let hours = Double(hoursString) else {
            isError = true
            submissionStatusMessage = "Please fill in valid hours"
            return
        }
        
        // Ensure signature data exists
        guard signaturePNGData != nil else {
            submissionStatusMessage = "Signature is missing."
            isError = true
            return
        }
        
        isLoading = true
        isError = false
        print("Date format before transformation \(submissionDate)")
        let dateString = isoDateFormatter.string(from: submissionDate)

        let initialSubmissionDTO = CreateSubmissionDto(
            orgName: orgName,
            hours: hours,
            submissionDate: dateString,
            description: description.isEmpty ? nil : description
        )
        
        print("Date being sent to backend: \(dateString)")
        do {
            // --- Step 1: Create initial submission record ---
            logger.info("Step 1: Creating initial submission record...")
            let createdSubmission = try await apiService.submitHours(submissionData: initialSubmissionDTO)
            let submissionId = createdSubmission.id
            logger.info("Step 1 Successful! Submission ID: \(submissionId)")
            submissionStatusMessage = "Record created, preparing signature upload..."
            
            // --- Step 2: Get S3 upload URL ---
            logger.info("Step 2: Getting signature upload URL...")
            let uploadInfo = try await apiService.getSignatureUploadUrl(submissionId: submissionId)
            logger.info("Step 2 Successful! Got S3 key: \(uploadInfo.key)")
            submissionStatusMessage = "Uploading signature..."
            
            guard let signaturePNG = signaturePNGData else {
                logger.error("Signature not found!")
                return
            }
            print("Data count BEFORE passing to APIService: \(signaturePNG.count) bytes")

            // --- Step 3: Upload signature to S3 ---
            logger.info("Step 3: Uploading signature data to S3...")
            try await apiService.uploadSignatureToS3(uploadUrl: uploadInfo.uploadUrl, imageData: signaturePNG)
            logger.info("Step 3 Successful! Signature uploaded.")
            submissionStatusMessage = "Saving signature reference..."
            
            // --- Step 4: Save S3 key reference to backend ---
            logger.info("Step 4: Saving signature reference to backend...")
            _ = try await apiService.saveSignatureReference(submissionId: submissionId, signatureKey: uploadInfo.key)
            logger.info("Step 4 Successful! Signature reference saved.")
            
            // --- Final Success ---
            submissionStatusMessage = "Submission complete!"
            isError = false
            
            // Wait briefly so user sees success message, then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            dismiss() // Dismiss the sheet
            
        } catch {
            logger.error("Submission failed: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized: submissionStatusMessage = "Authentication error. Please sign out and try again."
                case .serverError(_, let msg): submissionStatusMessage = "Server error: \(msg ?? "Please try again.")"
                case .requestFailed: submissionStatusMessage = "Network error. Please check connection."
                case .s3UploadFailed: submissionStatusMessage = "Failed to upload signature. Please try again."

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
        signatureImage = nil
        signaturePNGData = nil
    }
}
