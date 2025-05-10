//
//  SubmissionFormView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import SwiftUI
import os.log

struct DSInputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(DSColor.backgroundSecondary) // Or DSColor.backgroundSurface if you have it
            .foregroundColor(DSColor.textPrimary)   // For the typed text
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DSColor.border, lineWidth: 1)
            )
    }
}

extension View {
    func dsInputFieldStyle() -> some View {
        self.modifier(DSInputFieldStyle())
    }
}

struct SubmissionFormView: View {
    @State private var orgName: String = ""
    @State private var hoursString: String = "" // Collect hours as String for flexible input
    @State private var submissionDate: Date = Date() // Default to today
    @State private var description: String = ""
    // State for UI feedback
    @State private var isLoading: Bool = false
    @State private var submissionStatusMessage: String?
    @State private var isError: Bool = false
    
    // states dealing with supervisor's signature
    @State var isSupervisorSigning: Bool = false
    @State var clearSupervisorSignature: Bool = false
    @State var supervisorSignatureImage: UIImage? = nil
    @State var supervisorSignaturePDF: Data? = nil
    @State var supervisorSignaturePNGData: Data? = nil
    
    // states dealing with Pre Approved Signatures
    @State var isPreApprovedSigning: Bool = false
    @State var clearPreApprovedSignature: Bool = false
    @State var preApprovedSignatureImage: UIImage? = nil
    @State var preAppriovedSignaturePDF: Data? = nil
    @State var preApprovedSignaturePNGData: Data? = nil
    
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
        ZStack { // Apply global background
            DSColor.backgroundPrimary.ignoresSafeArea()
            NavigationView {
                VStack(alignment: .center, spacing: 10) {
                    Section("Submission details") {
                        TextField("Organization name", text: $orgName)
                            .dsInputFieldStyle()
                        TextField("Hours completed", text: $hoursString)
                            .keyboardType(.decimalPad)
                            .dsInputFieldStyle()
                        
                        DatePicker("Date Completed", selection: $submissionDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .tint(DSColor.accent) // Tint interactive parts of the picker
                            .foregroundColor(DSColor.textPrimary)
                        
                        VStack(alignment: .leading) {
                            Text("Description (Optional)")
                                .font(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .foregroundColor(DSColor.textPrimary) // For typed text
                                .scrollContentBackground(.hidden)
                                .background(DSColor.backgroundSecondary) // Or DSColor.backgroundSurface
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSColor.border, lineWidth:1))
                        }
                    }
                    
                    Section("Signatures") {
                        HStack(spacing: 15) { // Add spacing between signature pads
                            SignaturePadView(
                                title: "Supervisor",
                                isSigning: $isSupervisorSigning,
                                clearSignature: $clearSupervisorSignature,
                                signatureImage: $supervisorSignatureImage,
                                signaturePDF: $supervisorSignaturePDF,
                                signaturePNGData: $supervisorSignaturePNGData
                            )
                            
                            SignaturePadView(
                                title: "Pre-Approved",
                                isSigning: $isPreApprovedSigning,
                                clearSignature: $clearPreApprovedSignature,
                                signatureImage: $preApprovedSignatureImage,
                                signaturePDF: $preAppriovedSignaturePDF, // Corrected typo in binding
                                signaturePNGData: $preApprovedSignaturePNGData
                            )
                        }
                    }
                    
                    
                    if let statusMessage = submissionStatusMessage {
                        Text(statusMessage)
                            .font(.caption) // Consider DSFont.caption
                            .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
                            .frame(maxWidth: .infinity, alignment: .center)
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
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(DSColor.accent)
                        .foregroundColor(DSColor.textOnAccent)
                        .cornerRadius(8)
                        .controlSize(.large) // If you want a larger button
                        .disabled(isLoading || orgName.isEmpty || hoursString.isEmpty || supervisorSignatureImage == nil)
                    }
                }
                .navigationTitle("Log New Hours")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
            }
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
        
        guard supervisorSignaturePNGData != nil else {
            submissionStatusMessage = "Supervisor Signature is missing."
            isError = true
            return
        }
        
        guard preApprovedSignaturePNGData != nil else {
            submissionStatusMessage = "Pre Approved Signature is missing."
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
            logger.info("Step 2: Getting Supervisor signature upload URL...")
            let supervisorUploadInfo = try await apiService.getSupervisorSignatureUploadUrl(submissionId: submissionId)
            logger.info("Step 2 Successful! Got S3 key: \(supervisorUploadInfo.key)")
            submissionStatusMessage = "Uploading Supervisor signature..."
            
            guard let supervisorSignaturePNG = supervisorSignaturePNGData else {
                logger.error("Supervisor Signature not found!")
                return
            }
            
            print("Data count of Supervisor BEFORE passing to APIService: \(supervisorSignaturePNG.count) bytes")
            
            // --- Step 3: Upload signature to S3 ---
            logger.info("Step 3: Uploading Supervisor signature data to S3...")
            try await apiService.uploadSupervisorSignatureToS3(uploadUrl: supervisorUploadInfo.uploadUrl, imageData: supervisorSignaturePNG)
            logger.info("Step 3 Successful! Supervisor Signature uploaded.")
            submissionStatusMessage = "Saving Supervisor signature reference..."
            
            // --- Step 4: Save S3 key reference to backend ---
            logger.info("Step 4: Saving signature reference to backend...")
            _ = try await apiService.saveSupervisorSignatureReference(submissionId: submissionId, signatureKey: supervisorUploadInfo.key)
            logger.info("Step 4 Successful! Signature reference saved.")
            
            
            // --- Step 2: Get S3 upload URL ---
            logger.info("Step 2: Getting Pre Approved signature upload URL...")
            let preApprovedIploadInfo = try await apiService.getPreApprovedSignatureUploadUrl(submissionId: submissionId)
            logger.info("Step 2 Successful! Got S3 key: \(preApprovedIploadInfo.key)")
            submissionStatusMessage = "Uploading Pre Approved signature..."
            
            guard let preApprovedSignaturePNG = preApprovedSignaturePNGData else {
                logger.error("Pre Approved Signature not found!")
                return
            }
            
            print("Data count of Pre Approved BEFORE passing to APIService: \(preApprovedSignaturePNG.count) bytes")
            
            // --- Step 3: Upload signature to S3 ---
            logger.info("Step 3: Uploading Pre Approved signature data to S3...")
            try await apiService.uploadPreApprovedSignatureToS3(uploadUrl: preApprovedIploadInfo.uploadUrl, imageData: preApprovedSignaturePNG)
            logger.info("Step 3 Successful! Pre Approved Signature uploaded.")
            submissionStatusMessage = "Saving Pre Approved signature reference..."
            
            // --- Step 4: Save S3 key reference to backend ---
            logger.info("Step 4: Saving signature reference to backend...")
            _ = try await apiService.savePreApprovedSignatureReference(submissionId: submissionId, signatureKey: preApprovedIploadInfo.key)
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
    
    //    private func clearForm() {
    //        orgName = ""
    //        hoursString = ""
    //        submissionDate = Date() // Reset to today
    //        description = ""
    //        signatureImage = nil
    //        signaturePNGData = nil
    //    }
}

struct SignaturePadView: View {
    let title: String
    @Binding var isSigning: Bool
    @Binding var clearSignature: Bool
    @Binding var signatureImage: UIImage?
    @Binding var signaturePDF: Data?
    @Binding var signaturePNGData: Data?

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.headline) // Consider DSFont.headline
                .foregroundColor(DSColor.textPrimary)

            ZStack(alignment: isSigning ? .topTrailing : .center) { // Changed alignment for clear button
                SignatureViewContainer(
                    clearSignature: $clearSignature,
                    signatureImage: $signatureImage,
                    pdfSignature: $signaturePDF,
                    signaturePNGData: $signaturePNGData
                )
                .disabled(!isSigning)
                .frame(height: 150) // Adjusted height
                .frame(maxWidth: .infinity)
                .background(DSColor.backgroundSecondary) // Or DSColor.backgroundSurface, ensure it's not pure white if main bg is also white
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSigning ? DSColor.accent : DSColor.border, lineWidth: isSigning ? 3 : 1) // Dynamic border
                )

                if signatureImage != nil && !isSigning { // Show "Edit" if image exists and not currently signing
                    Button(action: {
                        isSigning = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .foregroundColor(DSColor.accent)
                            .frame(width: 30, height: 30)
                            .background(DSColor.backgroundPrimary.opacity(0.8)) // So it stands out
                            .clipShape(Circle())
                    }
                } else if isSigning {
                    Button(action: {
                        clearSignature = true // This will trigger the clear in SignatureViewContainer
                        signatureImage = nil // Also clear the image binding here
                        signaturePDF = nil
                        signaturePNGData = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DSColor.statusError)
                            .padding(5) // Padding around the clear button
                            .background(DSColor.backgroundSecondary.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(5) // Padding for the button itself for easier tapping
                } else { // No image, not signing -> "Sign Here"
                    Button(action: {
                        isSigning = true
                    }) {
                        VStack(alignment: .center, spacing: 4) { // Adjusted spacing
                            Image(systemName: "pencil.and.scribble") // More relevant icon
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(DSColor.textSecondary) // Changed from .black
                                .frame(width: 30, height: 30) // Adjusted size
                            Text("Sign here")
                                .font(.caption) // Consider DSFont.caption
                                .foregroundColor(DSColor.textPlaceholder) // Changed from .gray
                        }
                        .padding() // Add padding to make the tappable area larger
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Make button fill ZStack area
                }
            }
        }
    }
}
