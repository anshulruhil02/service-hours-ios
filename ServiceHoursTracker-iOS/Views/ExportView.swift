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
    
    // Signature states
    @State var isStudentSigning: Bool = false
    @State var clearStudentSignature: Bool = false
    @State var studentSignatureImage: UIImage? = nil
    @State var studentSignaturePDF: Data? = nil
    @State var studentSignaturePNGData: Data? = nil
    
    @State var isParentSigning: Bool = false
    @State var clearParentSignature: Bool = false
    @State var parentSignatureImage: UIImage? = nil
    @State var parentSignaturePDF: Data? = nil
    @State var parentSignaturePNGData: Data? = nil
    
    @State private var signatureStatusMessage: String?
    @State private var isError: Bool = false
    @State var previousStudentSignatureURL: URL?
    @State var previousParentSignatureURL: URL?
    
    private let apiService = APIService()
    
    var isAnySigning: Bool {
        return isStudentSigning || isParentSigning
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title and instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Signatures Required")
                        .font(.headline)
                        .foregroundColor(DSColor.textPrimary)
                    
                    Text("Please provide both student and parent/guardian signatures to generate your service hours report.")
                        .font(.subheadline)
                        .foregroundColor(DSColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Student Signature Section
                VStack(spacing: 12) {
                    Text("Student Signature")
                        .font(.headline)
                        .foregroundColor(DSColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if previousStudentSignatureURL == nil {
                        SignaturePadView(
                            title: "Student",
                            isSigning: $isStudentSigning,
                            clearSignature: $clearStudentSignature,
                            signatureImage: $studentSignatureImage,
                            signaturePDF: $studentSignaturePDF,
                            signaturePNGData: $studentSignaturePNGData
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DSColor.border, lineWidth: 1)
                        )
                        
                        Button {
                            Task {
                                await saveStudentSignature()
                            }
                        } label: {
                            Text("Save Student Signature")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(studentSignaturePNGData != nil ? DSColor.accent : DSColor.backgroundSecondary)
                        .foregroundColor(studentSignaturePNGData != nil ? DSColor.textOnAccent : DSColor.textSecondary)
                        .disabled(studentSignaturePNGData == nil)
                        .cornerRadius(8)
                        .controlSize(.large)
                    } else {
                        VStack(spacing: 8) {
                            Text("Signature Saved")
                                .font(.subheadline)
                                .foregroundColor(DSColor.statusSuccess)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            AsyncImage(url: previousStudentSignatureURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 150)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(DSColor.border, lineWidth: 1)
                                        )
                                        .background(.white)
                                case .failure:
                                    SignatureErrorView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                            
                            Button("Change Signature") {
                                previousStudentSignatureURL = nil
                                studentSignaturePNGData = nil
                                studentSignatureImage = nil
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(DSColor.accent)
                            .font(.subheadline)
                        }
                        .padding()
                        .background(DSColor.backgroundSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Parent Signature Section
                VStack(spacing: 12) {
                    Text("Parent/Guardian Signature")
                        .font(.headline)
                        .foregroundColor(DSColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if previousParentSignatureURL == nil {
                        SignaturePadView(
                            title: "Parent/Guardian",
                            isSigning: $isParentSigning,
                            clearSignature: $clearParentSignature,
                            signatureImage: $parentSignatureImage,
                            signaturePDF: $parentSignaturePDF,
                            signaturePNGData: $parentSignaturePNGData
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DSColor.border, lineWidth: 1)
                        )
                        
                        Button {
                            Task {
                                await saveParentSignature()
                            }
                        } label: {
                            Text("Save Parent/Guardian Signature")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(parentSignaturePNGData != nil ? DSColor.accent : DSColor.backgroundSecondary)
                        .foregroundColor(parentSignaturePNGData != nil ? DSColor.textOnAccent : DSColor.textSecondary)
                        .disabled(parentSignaturePNGData == nil)
                        .cornerRadius(8)
                        .controlSize(.large)
                    } else {
                        VStack(spacing: 8) {
                            Text("Signature Saved")
                                .font(.subheadline)
                                .foregroundColor(DSColor.statusSuccess)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            AsyncImage(url: previousParentSignatureURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 150)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150)
                                        .cornerRadius(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(DSColor.border, lineWidth: 1)
                                        )
                                        .background(.white)
                                case .failure:
                                    SignatureErrorView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                            
                            Button("Change Signature") {
                                previousParentSignatureURL = nil
                                parentSignaturePNGData = nil
                                parentSignatureImage = nil
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(DSColor.accent)
                            .font(.subheadline)
                        }
                        .padding()
                        .background(DSColor.backgroundSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
                
                // Status message
                if let statusMessage = signatureStatusMessage {
                    HStack {
                        Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
                        Text(statusMessage)
                            .font(.callout)
                            .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        (isError ? DSColor.statusError : DSColor.statusSuccess).opacity(0.1)
                    )
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 24)
                
                // Generate Report Button
                Button {
                    Task {
                        logger.info("Generate Report button tapped.")
                        await viewModel.generateAndPreparePdfReport()
                        
                        // Directly present the share sheet once PDF is ready
                        if let pdfURL = viewModel.pdfReportFileUrl {
                            // Use UIActivityViewController directly
                            await MainActor.run {
                                presentShareSheet(with: pdfURL)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.pdfReportFileUrl == nil && viewModel.isGeneratingReport {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "doc.fill")
                        }
                        Text(viewModel.pdfReportFileUrl == nil && viewModel.isGeneratingReport ? "Generating PDF, this might take a few seconds..." : "Generate & Share PDF Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(DSColor.primary)
                .controlSize(.large)
                .disabled(viewModel.isGeneratingReport || previousStudentSignatureURL == nil || previousParentSignatureURL == nil)
                .opacity((previousStudentSignatureURL == nil || previousParentSignatureURL == nil) ? 0.6 : 1.0)
                
                if previousStudentSignatureURL == nil || previousParentSignatureURL == nil {
                    Text("Both signatures are required to generate a report")
                        .font(.caption)
                        .foregroundColor(DSColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                
                if viewModel.isGeneratingReport {
                    ProgressView("Preparing report...")
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .scrollDisabled(isAnySigning)
        .navigationTitle("Signature & Export")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile()
            await studentSignatureURL()
            await parentSignatureURL()
        }
        //        .sheet(isPresented: $viewModel.showingShareSheet, onDismiss: {
        //            // Clean up the temporary file when the sheet is dismissed
        //            if let url = viewModel.pdfReportFileUrl {
        //                do {
        //                    try FileManager.default.removeItem(at: url)
        //                    logger.info("Removed temporary PDF file: \(url.path)")
        //                } catch {
        //                    logger.error("Error removing temporary PDF file: \(error.localizedDescription)")
        //                }
        //            }
        //            viewModel.pdfReportFileUrl = nil // Clear URL
        //            viewModel.reportError = nil
        //            logger.info("Share sheet dismissed.")
        //        }) {
        //            // This content is shown inside the presented sheet.
        //            if let pdfURL = viewModel.pdfReportFileUrl {
        //                ShareLink(
        //                    item: pdfURL,
        //                    preview: SharePreview(
        //                        "Community Hours Report.pdf",
        //                        image: Image(systemName: "doc.richtext.fill")
        //                    )
        //                ) {
        //                    Label("Share Report", systemImage: "square.and.arrow.up")
        //                        .font(.headline)
        //                        .padding()
        //                }
        //            } else {
        //                VStack(spacing: 16) {
        //                    Text("Preparing your report...")
        //                        .font(.headline)
        //                    ProgressView()
        //                }
        //                .padding()
        //            }
        //        }
    }
    
    // Helper view for signature loading errors
    private struct SignatureErrorView: View {
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .foregroundColor(DSColor.statusWarning)
                    .font(.largeTitle)
                Text("Could not load signature")
                    .font(.caption)
                    .foregroundColor(DSColor.textSecondary)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(DSColor.backgroundSecondary.opacity(0.5))
        }
    }
    
    private func saveStudentSignature() async {
        isStudentSigning = false
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
        isParentSigning = false
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
    
    // Add this function to present the share sheet directly:
    private func presentShareSheet(with url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            if let presentedViewController = window.rootViewController?.presentedViewController {
                // If there's already a presented view controller, present from it
                activityViewController.popoverPresentationController?.sourceView = window
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
                
                presentedViewController.present(activityViewController, animated: true)
            } else {
                // Present from root view controller
                activityViewController.popoverPresentationController?.sourceView = window
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = []
                
                window.rootViewController?.present(activityViewController, animated: true)
            }
        }
        
        // Clean up the temporary file when sharing is complete
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            do {
                try FileManager.default.removeItem(at: url)
                logger.info("Removed temporary PDF file: \(url.path)")
            } catch {
                logger.error("Error removing temporary PDF file: \(error.localizedDescription)")
            }
            viewModel.pdfReportFileUrl = nil
            viewModel.reportError = nil
        }
    }
}
