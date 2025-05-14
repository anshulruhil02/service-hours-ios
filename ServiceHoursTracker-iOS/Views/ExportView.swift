//
//  ExportView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

// Views/ExportView.swift

import SwiftUI
import os.log

struct ExportView: View {
    @ObservedObject var viewModel: HomeViewModel
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExportView")
    @State var isStudentSigning: Bool = false
    @State var clearStudentSignature: Bool = false
    @State var studentSignatureImage: UIImage? = nil
    @State var studentSignaturePDF: Data? = nil
    @State var studentSignaturePNGData: Data? = nil
    @State private var signatureStatusMessage: String?
    @State private var isError: Bool = false
    @State var isParentSigning: Bool = false
    @State var clearParentSignature: Bool = false
    @State var parentSignatureImage: UIImage? = nil
    @State var parentSignaturePDF: Data? = nil
    @State var parentSignaturePNGData: Data? = nil
    @State var previousStudentSignatureURL: URL?
    @State var previousParentSignatureURL: URL?
    private let apiService = APIService()
    
    
    var body: some View {
        VStack {
            if previousStudentSignatureURL == nil {
                SignaturePadView(
                    title: "Student Signature",
                    isSigning: $isStudentSigning,
                    clearSignature: $clearStudentSignature,
                    signatureImage: $studentSignatureImage,
                    signaturePDF: $studentSignaturePDF,
                    signaturePNGData: $studentSignaturePNGData
                )
                
                Button("Submit student signature") {
                    Task {
                        await saveStudentSignature()
                    }
                }
            } else {
                VStack {
                    Text("Supervisor signature")
                        .foregroundStyle(DSColor.textPrimary)
                    
                    AsyncImage(url: previousStudentSignatureURL) { phase in
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
                }
            }
            
            
            if previousParentSignatureURL == nil {
                SignaturePadView(
                    title: "Parent/Guardian Signature",
                    isSigning: $isParentSigning,
                    clearSignature: $clearParentSignature,
                    signatureImage: $parentSignatureImage,
                    signaturePDF: $parentSignaturePDF,
                    signaturePNGData: $parentSignaturePNGData
                )
                
                Button("Submit parent/guardian signature") {
                    Task {
                        await saveParentSignature()
                    }
                }
            }else {
                VStack {
                    Text("Parent/Gurdian signature")
                        .foregroundStyle(DSColor.textPrimary)
                    
                    AsyncImage(url: previousParentSignatureURL) { phase in
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
                }
            }
            
            
            if let statusMessage = signatureStatusMessage {
                Text(statusMessage)
                    .font(.caption) // Consider DSFont.caption
                    .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 5)
            }
            
            Button {
                Task {
                    logger.info("Generate Report button tapped.")
                    await viewModel.generateAndPreparePdfReport()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isGeneratingReport { ProgressView().tint(.white) }
                    else { Label("Generate & Share PDF Report", systemImage: "square.and.arrow.up.fill").fontWeight(.semibold) }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent).tint(DSColor.primary).controlSize(.large)
            .disabled(viewModel.isGeneratingReport).padding(.top)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile()
            await studentSignatureURL()
            await parentSignatureURL()
        }
        // This sheet modifier will present when 'showingShareSheet' becomes true
        .sheet(isPresented: $viewModel.showingShareSheet, onDismiss: {
            // Clean up the temporary file when the sheet is dismissed
            if let url = viewModel.pdfReportFileUrl {
                do {
                    try FileManager.default.removeItem(at: url)
                    logger.info("Removed temporary PDF file: \(url.path)")
                } catch {
                    logger.error("Error removing temporary PDF file: \(error.localizedDescription)")
                }
            }
            viewModel.pdfReportFileUrl = nil // Clear URL
            viewModel.reportError = nil
            logger.info("Share sheet dismissed.")
        }) {
            // This content is shown inside the presented sheet.
            // The ShareLink, when its item is valid, will trigger the system share UI.
            if let pdfURL = viewModel.pdfReportFileUrl { // Use the file URL
                ShareLink(
                    item: pdfURL, // <-- Pass the URL of the saved PDF file
                    preview: SharePreview(
                        "Community Hours Report.pdf", // Suggested filename
                        image: Image(systemName: "doc.richtext.fill")
                    )
                ) {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                }
            } else {
                VStack {
                    Text("Preparing report for sharing...")
                    ProgressView()
                }
            }
        }
    }
    
    private func saveStudentSignature() async {
        isError = false
        do {
            if let studentSignaturePNG =  studentSignaturePNGData {
                logger.info("Step 2: Getting Supervisor signature upload URL...")
                
                // Check if user profile exists
                guard let userProfile = viewModel.userProfile else {
                    logger.error("No user profile found")
                    signatureStatusMessage = "Unable to get user profile. Please try again."
                    isError = true
                    return
                }
                let studentUploadInfo = try await apiService.getStudentSignatureUploadUrl(userId: userProfile.id)
                logger.info("Step 2 Successful! Got S3 key: \(studentUploadInfo.key)")
                signatureStatusMessage = "Uploading Supervisor signature..."
                
                
                
                print("Data count of Supervisor BEFORE passing to APIService: \(studentSignaturePNG.count) bytes")
                
                // --- Step 3: Upload signature to S3 ---
                logger.info("Step 3: Uploading Supervisor signature data to S3...")
                try await apiService.uploadStudentSignatureToS3(uploadUrl: studentUploadInfo.uploadUrl, imageData: studentSignaturePNG)
                logger.info("Step 3 Successful! Supervisor Signature uploaded.")
                signatureStatusMessage = "Saving Supervisor signature reference..."
                
                // --- Step 4: Save S3 key reference to backend ---
                logger.info("Step 4: Saving signature reference to backend...")
                _ = try await apiService.saveStudentSignatureReference(userId: userProfile.id, signatureKey: studentUploadInfo.key)
                logger.info("Step 4 Successful! Signature reference saved.")
            }
        } catch {
            logger.error("Submission failed: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized: signatureStatusMessage = "Authentication error. Please sign out and try again."
                case .serverError(_, let msg): signatureStatusMessage = "Server error: \(msg ?? "Please try again.")"
                case .requestFailed: signatureStatusMessage = "Network error. Please check connection."
                case .s3UploadFailed: signatureStatusMessage = "Failed to upload signature. Please try again."
                    
                default: signatureStatusMessage = "Could not submit hours. Please try again."
                }
            } else {
                signatureStatusMessage = "An unexpected error occurred."
            }
            isError = true
            dump(error)
        }
        
        isError = false
        await studentSignatureURL()
    }
    
    private func saveParentSignature() async {
        isError = false
        do {
            if let parentSignaturePNG =  parentSignaturePNGData {
                logger.info("Step 2: Getting Supervisor signature upload URL...")
                
                // Check if user profile exists
                guard let userProfile = viewModel.userProfile else {
                    logger.error("No user profile found")
                    signatureStatusMessage = "Unable to get user profile. Please try again."
                    isError = true
                    return
                }
                let parentUploadInfo = try await apiService.getParentSignatureUploadUrl(userId: userProfile.id)
                logger.info("Step 2 Successful! Got S3 key: \(parentUploadInfo.key)")
                signatureStatusMessage = "Uploading Supervisor signature..."
                
                
                
                print("Data count of Supervisor BEFORE passing to APIService: \(parentSignaturePNG.count) bytes")
                
                // --- Step 3: Upload signature to S3 ---
                logger.info("Step 3: Uploading Supervisor signature data to S3...")
                try await apiService.uploadParentSignatureToS3(uploadUrl: parentUploadInfo.uploadUrl, imageData: parentSignaturePNG)
                logger.info("Step 3 Successful! Supervisor Signature uploaded.")
                signatureStatusMessage = "Saving Supervisor signature reference..."
                
                // --- Step 4: Save S3 key reference to backend ---
                logger.info("Step 4: Saving signature reference to backend...")
                _ = try await apiService.saveParentSignatureReference(userId: userProfile.id, signatureKey: parentUploadInfo.key)
                logger.info("Step 4 Successful! Signature reference saved.")
            }
        } catch {
            logger.error("Submission failed: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized: signatureStatusMessage = "Authentication error. Please sign out and try again."
                case .serverError(_, let msg): signatureStatusMessage = "Server error: \(msg ?? "Please try again.")"
                case .requestFailed: signatureStatusMessage = "Network error. Please check connection."
                case .s3UploadFailed: signatureStatusMessage = "Failed to upload signature. Please try again."
                    
                default: signatureStatusMessage = "Could not submit hours. Please try again."
                }
            } else {
                signatureStatusMessage = "An unexpected error occurred."
            }
            isError = true
            dump(error)
        }
        
        isError = false
        await parentSignatureURL()
    }
    
    private func studentSignatureURL() async {
        guard let userProfile = viewModel.userProfile else {
            logger.error("No user profile found")
            signatureStatusMessage = "Unable to get user profile. Please try again."
            isError = true
            return
        }
        do {
            previousStudentSignatureURL = try await apiService.getStudentSignatureViewUrl(userId: userProfile.id)
        } catch {
            logger.log("Previous student signature does not exist")
            previousStudentSignatureURL = nil
        }
    }
    
    private func parentSignatureURL() async {
        guard let userProfile = viewModel.userProfile else {
            logger.error("No user profile found")
            signatureStatusMessage = "Unable to get user profile. Please try again."
            isError = true
            return
        }
        do {
            previousParentSignatureURL = try await apiService.getParentSignatureViewUrl(userId: userProfile.id)
        } catch {
            logger.log("Previous Parent signature does not exist")
            previousParentSignatureURL = nil
        }
    }
}
