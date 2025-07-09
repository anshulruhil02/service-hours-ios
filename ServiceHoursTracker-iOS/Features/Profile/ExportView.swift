//
//  ExportView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI
import os.log

struct ExportView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExportView")
    
    // Signature states
    @State var isStudentSigning: Bool = false
    @State var clearStudentSignature: Bool = false
    @State var studentSignatureImage: UIImage? = nil
    @State var studentSignaturePNGData: Data? = nil
    
    @State var isParentSigning: Bool = false
    @State var clearParentSignature: Bool = false
    @State var parentSignatureImage: UIImage? = nil
    @State var parentSignaturePNGData: Data? = nil
    
    @State private var signatureStatusMessage: String?
    @State private var isError: Bool = false
    @State var previousStudentSignatureURL: URL?
    @State var previousParentSignatureURL: URL?
    
    private let apiService = APIService()
    
    var isAnySigning: Bool {
        return isStudentSigning || isParentSigning
    }
    
    var allSignaturesComplete: Bool {
        return previousStudentSignatureURL != nil && previousParentSignatureURL != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                // Header Section
                VStack(spacing: DSSpacing.md) {
                    VStack(spacing: DSSpacing.sm) {
                        Text("Digital Signatures Required")
                            .font(DSTypography.title)
                            .foregroundColor(DSColor.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Both student and parent/guardian signatures are required to generate your official service hours report.")
                            .font(DSTypography.subheadline)
                            .foregroundColor(DSColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    // Progress indicator
                    HStack(spacing: DSSpacing.md) {
                        SignatureProgressDot(
                            isCompleted: previousStudentSignatureURL != nil,
                            label: "Student"
                        )
                        
                        Rectangle()
                            .fill(DSColor.border)
                            .frame(height: 2)
                            .frame(maxWidth: 60)
                        
                        SignatureProgressDot(
                            isCompleted: previousParentSignatureURL != nil,
                            label: "Parent"
                        )
                    }
                    .padding(.top, DSSpacing.md)
                }
                .padding(.horizontal, DSSpacing.lg)
                
                // Student Signature Section
                SignatureSection(
                    title: "Student Signature",
                    isCompleted: previousStudentSignatureURL != nil,
                    isSigning: $isStudentSigning,
                    clearSignature: $clearStudentSignature,
                    signatureImage: $studentSignatureImage,
                    signaturePNGData: $studentSignaturePNGData,
                    previousSignatureURL: previousStudentSignatureURL,
                    onSave: {
                        Task {
                            await saveStudentSignature()
                        }
                    },
                    onChangeSignature: {
                        previousStudentSignatureURL = nil
                        studentSignaturePNGData = nil
                        studentSignatureImage = nil
                    }
                )
                
                // Parent Signature Section
                SignatureSection(
                    title: "Parent/Guardian Signature",
                    isCompleted: previousParentSignatureURL != nil,
                    isSigning: $isParentSigning,
                    clearSignature: $clearParentSignature,
                    signatureImage: $parentSignatureImage,
                    signaturePNGData: $parentSignaturePNGData,
                    previousSignatureURL: previousParentSignatureURL,
                    onSave: {
                        Task {
                            await saveParentSignature()
                        }
                    },
                    onChangeSignature: {
                        previousParentSignatureURL = nil
                        parentSignaturePNGData = nil
                        parentSignatureImage = nil
                    }
                )
                
                // Status message
                if let statusMessage = signatureStatusMessage {
                    StatusMessageView(
                        message: statusMessage,
                        isError: isError
                    )
                    .padding(.horizontal, DSSpacing.lg)
                }
                
                Spacer(minLength: DSSpacing.xxl)
                
                // Generate Report Section
                VStack(spacing: DSSpacing.lg) {
                    DSButton(viewModel.isGeneratingReport ? "Generating PDF..." : "Generate & Share PDF Report") {
                        Task {
                            studentSignatureImage = nil
                            studentSignaturePNGData = nil
                            parentSignatureImage = nil
                            parentSignaturePNGData = nil
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
                    }
                    .buttonStyle(.primary)
                    .buttonSize(.large)
                    .fullWidth()
                    .leadingIcon(viewModel.isGeneratingReport ? nil : Image(systemName: "doc.fill"))
                    .loading(viewModel.isGeneratingReport)
                    .enabled(allSignaturesComplete && !viewModel.isGeneratingReport)
                    
                    if !allSignaturesComplete {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(DSColor.statusInfo)
                                .font(.caption)
                            
                            Text("Complete both signatures above to generate your report")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColor.textSecondary)
                        }
                    }
                    
                    if viewModel.isGeneratingReport {
                        VStack(spacing: DSSpacing.sm) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("This may take a few moments...")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColor.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .background(DSColor.backgroundSecondary)
        .scrollDisabled(isAnySigning)
        .navigationTitle("Export Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.userProfile == nil {
                Task {
                    await viewModel.fetchUserProfile()
                    await studentSignatureURL()
                    await parentSignatureURL()
                }
            }
        }
        .toolbar {
            sharedToolbarItems(currentTab: .exportTab, coordinator: navigationCoordinator)
        }
    }
    
    // MARK: - API Methods (unchanged)
    
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
                signatureStatusMessage = "Uploading Student signature..."
                
                print("Data count of Student BEFORE passing to APIService: \(studentSignaturePNG.count) bytes")
                
                // --- Step 3: Upload signature to S3 ---
                logger.info("Step 3: Uploading Student signature data to S3...")
                try await apiService.uploadStudentSignatureToS3(uploadUrl: studentUploadInfo.uploadUrl, imageData: studentSignaturePNG)
                logger.info("Step 3 Successful! Student Signature uploaded.")
                signatureStatusMessage = "Saving Student signature reference..."
                
                // --- Step 4: Save S3 key reference to backend ---
                logger.info("Step 4: Saving signature reference to backend...")
                _ = try await apiService.saveStudentSignatureReference(userId: userProfile.id, signatureKey: studentUploadInfo.key)
                logger.info("Step 4 Successful! Signature reference saved.")
                signatureStatusMessage = "Student signature saved successfully!"
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
                logger.info("Step 2: Getting Parent signature upload URL...")
                
                // Check if user profile exists
                guard let userProfile = viewModel.userProfile else {
                    logger.error("No user profile found")
                    signatureStatusMessage = "Unable to get user profile. Please try again."
                    isError = true
                    return
                }
                let parentUploadInfo = try await apiService.getParentSignatureUploadUrl(userId: userProfile.id)
                logger.info("Step 2 Successful! Got S3 key: \(parentUploadInfo.key)")
                signatureStatusMessage = "Uploading Parent signature..."
                
                print("Data count of Parent BEFORE passing to APIService: \(parentSignaturePNG.count) bytes")
                
                // --- Step 3: Upload signature to S3 ---
                logger.info("Step 3: Uploading Parent signature data to S3...")
                try await apiService.uploadParentSignatureToS3(uploadUrl: parentUploadInfo.uploadUrl, imageData: parentSignaturePNG)
                logger.info("Step 3 Successful! Parent Signature uploaded.")
                signatureStatusMessage = "Saving Parent signature reference..."
                
                // --- Step 4: Save S3 key reference to backend ---
                logger.info("Step 4: Saving signature reference to backend...")
                _ = try await apiService.saveParentSignatureReference(userId: userProfile.id, signatureKey: parentUploadInfo.key)
                logger.info("Step 4 Successful! Signature reference saved.")
                signatureStatusMessage = "Parent signature saved successfully!"
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

// MARK: - Supporting Views

struct SignatureProgressDot: View {
    let isCompleted: Bool
    let label: String
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            ZStack {
                Circle()
                    .fill(isCompleted ? DSColor.statusSuccess : DSColor.backgroundSecondary)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isCompleted ? DSColor.statusSuccess : DSColor.border, lineWidth: 2)
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(DSColor.textOnPrimary)
                }
            }
            
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(isCompleted ? DSColor.statusSuccess : DSColor.textSecondary)
        }
    }
}

struct SignatureSection: View {
    let title: String
    let isCompleted: Bool
    
    @Binding var isSigning: Bool
    @Binding var clearSignature: Bool
    @Binding var signatureImage: UIImage?
    @Binding var signaturePNGData: Data?
    
    let previousSignatureURL: URL?
    let onSave: () -> Void
    let onChangeSignature: () -> Void
    
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            HStack {
                Text(title)
                    .font(DSTypography.headline)
                    .foregroundColor(DSColor.textPrimary)
                
                Spacer()
                
                if isCompleted {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DSColor.statusSuccess)
                            .font(.caption)
                        
                        Text("Completed")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.statusSuccess)
                    }
                }
            }
            
            if previousSignatureURL == nil {
                // Signature input section
                VStack(spacing: DSSpacing.md) {
                    SignaturePadView(
                        title: "",
                        isSigning: $isSigning,
                        clearSignature: $clearSignature,
                        signatureImage: $signatureImage,
                        signaturePNGData: $signaturePNGData
                    )
                    .frame(height: 160)
                    .background(DSColor.backgroundSecondary)
                    .cornerRadius(DSRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.md)
                            .stroke(DSColor.border, lineWidth: 1)
                    )
                    
                    DSButton("Save Signature") {
                        onSave()
                    }
                    .buttonStyle(.primary)
                    .buttonSize(.medium)
                    .fullWidth()
                    .enabled(signaturePNGData != nil)
                }
            } else {
                // Completed signature display
                VStack(spacing: DSSpacing.md) {
                    AsyncImage(url: previousSignatureURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 120)
                                .background(Color.white)
                                .cornerRadius(DSRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DSRadius.sm)
                                        .stroke(DSColor.border, lineWidth: 1)
                                )
                        case .failure:
                            SignatureErrorView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    DSButton("Change Signature") {
                        onChangeSignature()
                    }
                    .buttonStyle(.ghost)
                    .buttonSize(.medium)
                }
                .padding(DSSpacing.lg)
                .background(DSColor.statusSuccess.opacity(0.05))
                .cornerRadius(DSRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .stroke(DSColor.statusSuccess.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
}

struct StatusMessageView: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
            
            Text(message)
                .font(DSTypography.subheadline)
                .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
            
            Spacer()
        }
        .padding(DSSpacing.lg)
        .background((isError ? DSColor.statusError : DSColor.statusSuccess).opacity(0.1))
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke((isError ? DSColor.statusError : DSColor.statusSuccess).opacity(0.3), lineWidth: 1)
        )
    }
}

// Helper view for signature loading errors
private struct SignatureErrorView: View {
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DSColor.statusWarning)
                .font(DSTypography.headline)
            Text("Could not load signature")
                .font(DSTypography.caption)
                .foregroundColor(DSColor.textSecondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(DSColor.backgroundSecondary.opacity(0.5))
        .cornerRadius(DSRadius.sm)
    }
}
