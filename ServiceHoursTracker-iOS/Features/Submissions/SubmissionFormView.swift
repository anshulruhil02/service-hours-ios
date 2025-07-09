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
            .padding(DSSpacing.lg)
            .background(DSColor.backgroundSecondary)
            .foregroundColor(DSColor.textPrimary)
            .cornerRadius(DSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .stroke(DSColor.border, lineWidth: 1)
            )
    }
}

extension View {
    func dsInputFieldStyle() -> some View {
        self.modifier(DSInputFieldStyle())
    }
}

enum Field: Hashable {
    case orgName, hours, telephone, supervisorName, description
    case supervisorSignature, preApprovedSignature
}

struct SubmissionFormView: View {
    @State private var orgName: String = ""
    @State private var hoursString: String = ""
    @State private var telephone: String = ""
    @State private var supervisorName: String = ""
    @State private var submissionDate: Date = Date()
    @State private var description: String = ""
    @FocusState private var focusedField: Field?
    
    // State for UI feedback
    @State private var isLoading: Bool = false
    @State private var submissionStatusMessage: String?
    @State private var isError: Bool = false
    
    // states dealing with supervisor's signature
    @State var isSupervisorSigning: Bool = false
    @State var clearSupervisorSignature: Bool = false
    @State var supervisorSignatureImage: UIImage? = nil
    @State var supervisorSignaturePNGData: Data? = nil
    
    // states dealing with Pre Approved Signatures
    @State var isPreApprovedSigning: Bool = false
    @State var clearPreApprovedSignature: Bool = false
    @State var preApprovedSignatureImage: UIImage? = nil
    @State var preApprovedSignaturePNGData: Data? = nil
    var submissionToEdit: SubmissionResponse?
    var previousSubmissionExists: Bool {
        return submissionToEdit != nil
    }
    var isAnySigning: Bool {
        return isSupervisorSigning || isPreApprovedSigning
    }
    @State var previousSupervisorSignatureURL: URL?
    @State var previousPreAprrovedSignatureURL: URL?
    
    // New states for delete functionality
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteError: String? = nil
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    
    
    // API Service instance (consider injecting later)
    private let apiService = APIService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubmissionFormView")
    
    init(existingSubmission: SubmissionResponse? = nil) {
        submissionToEdit = existingSubmission
        if let submission = existingSubmission {
            _orgName = State(initialValue: submission.orgName ?? "")
            _hoursString = State(initialValue: submission.hours.map { String($0) } ?? "")
            _submissionDate = State(initialValue: submission.submissionDate)
            _description = State(initialValue: submission.description ?? "")
            _telephone = State(initialValue: submission.telephone.map { String($0) } ?? "")
            _supervisorName = State(initialValue: submission.supervisorName ?? "")
        }
    }
    
    var allFieldsValid: Bool {
        return !orgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !hoursString.isEmpty &&
        Double(hoursString) != nil &&
        !telephone.isEmpty &&
        Double(telephone) != nil &&
        !supervisorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var signaturesComplete: Bool {
        let supervisorComplete = supervisorSignaturePNGData != nil || previousSupervisorSignatureURL != nil
        let preApprovedComplete = preApprovedSignaturePNGData != nil || previousPreAprrovedSignatureURL != nil
        return supervisorComplete && preApprovedComplete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DSSpacing.xxl) {
                    // Header Section
                    VStack(spacing: DSSpacing.md) {
                        Text(previousSubmissionExists ? "Edit Service Hours" : "Log Service Hours")
                            .font(DSTypography.title)
                            .foregroundColor(DSColor.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(previousSubmissionExists ? "Update your service hour entry" : "Record your community service experience")
                            .font(DSTypography.subheadline)
                            .foregroundColor(DSColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Form Progress Indicator
                    FormProgressView(
                        formComplete: allFieldsValid,
                        signaturesComplete: signaturesComplete
                    )
                    
                    // Basic Information Section
                    FormSection(title: "Service Details", icon: "info.circle.fill") {
                        VStack(spacing: DSSpacing.lg) {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                HStack {
                                    Text("Organization Name")
                                        .font(DSTypography.subheadline)
                                        .foregroundColor(DSColor.textPrimary)
                                    Text("*")
                                        .font(DSTypography.subheadline)
                                        .foregroundColor(DSColor.statusError)
                                }
                                
                                DSTextField(
                                    "e.g., Local Food Bank",
                                    text: $orgName,
                                    leadingImage: Image(systemName: "building.2"),
                                    keyboardType: .default,
                                    textContentType: .organizationName
                                )
                                .focused($focusedField, equals: .orgName)
                            }
                            
                            HStack(spacing: DSSpacing.md) {
                                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                    HStack {
                                        Text("Hours Completed")
                                            .font(DSTypography.subheadline)
                                            .foregroundColor(DSColor.textPrimary)
                                        Text("*")
                                            .font(DSTypography.subheadline)
                                            .foregroundColor(DSColor.statusError)
                                    }
                                    
                                    DSTextField(
                                        "8.5",
                                        text: $hoursString,
                                        leadingImage: Image(systemName: "clock"),
                                        keyboardType: .decimalPad
                                    )
                                    .focused($focusedField, equals: .hours)
                                }
                                
                                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                    HStack {
                                        Text("Contact Phone")
                                            .font(DSTypography.subheadline)
                                            .foregroundColor(DSColor.textPrimary)
                                        Text("*")
                                            .font(DSTypography.subheadline)
                                            .foregroundColor(DSColor.statusError)
                                    }
                                    
                                    DSTextField(
                                        "(555) 123-4567",
                                        text: $telephone,
                                        leadingImage: Image(systemName: "phone"),
                                        keyboardType: .phonePad,
                                        textContentType: .telephoneNumber
                                    )
                                    .focused($focusedField, equals: .telephone)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                HStack {
                                    Text("Supervisor Name")
                                        .font(DSTypography.subheadline)
                                        .foregroundColor(DSColor.textPrimary)
                                    Text("*")
                                        .font(DSTypography.subheadline)
                                        .foregroundColor(DSColor.statusError)
                                }
                                
                                DSTextField(
                                    "Full name of supervising staff",
                                    text: $supervisorName,
                                    leadingImage: Image(systemName: "person.circle"),
                                    keyboardType: .default,
                                    textContentType: .name
                                )
                                .focused($focusedField, equals: .supervisorName)
                            }
                            
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                        HStack {
                                            Text("Service Description")
                                                .font(DSTypography.subheadline)
                                                .foregroundColor(DSColor.textPrimary)
                                            Text("*")
                                                .font(DSTypography.subheadline)
                                                .foregroundColor(DSColor.statusError)
                                        }
                                        
                                        ZStack(alignment: .topLeading) {
                                            TextEditor(text: $description)
                                                .font(DSTypography.bodyMedium)
                                                .foregroundColor(DSColor.textPrimary)
                                                .padding(DSSpacing.lg)
                                                .background(Color.white)
                                                .cornerRadius(DSRadius.md)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: DSRadius.md)
                                                        .stroke(DSColor.border.opacity(0.3), lineWidth: 1)
                                                )
                                                .frame(minHeight: 100)
                                                .focused($focusedField, equals: .description)
                                                .scrollContentBackground(.hidden)
                                            
                                            if description.isEmpty {
                                                Text("Describe the service activities you performed...")
                                                    .font(DSTypography.caption)
                                                    .foregroundColor(DSColor.disabledText)
                                                    .padding(.leading, DSSpacing.lg + 4) // +4 for TextEditor's internal padding
                                                    .padding(.top, DSSpacing.lg + 8)     // +8 for TextEditor's internal padding
                                                    .allowsHitTesting(false)
                                            }
                                        }
                                    }
                        }
                    }
                    
                    // Signature Section
                    FormSection(title: "Required Signatures", icon: "signature") {
                        VStack(spacing: DSSpacing.xl) {
                            if isAnySigning {
                                SigningModeBar(
                                    isSupervisorSigning: $isSupervisorSigning,
                                    isPreApprovedSigning: $isPreApprovedSigning,
                                    onCancelSupervisor: { cancelSupervisorSigning() },
                                    onCancelPreApproved: { cancelPreApprovedSigning() }
                                )
                            }
                            
                            VStack(spacing: DSSpacing.lg) {
                                // Supervisor Signature
                                SignatureInputView(
                                    title: "Supervisor Signature",
                                    subtitle: "Signature from your supervising staff member",
                                    isSigning: $isSupervisorSigning,
                                    clearSignature: $clearSupervisorSignature,
                                    signatureImage: $supervisorSignatureImage,
                                    signaturePNGData: $supervisorSignaturePNGData,
                                    previousSignatureURL: previousSupervisorSignatureURL
                                )
                                
                                // Pre-Approved Signature
                                SignatureInputView(
                                    title: "Pre-Approved Signature",
                                    subtitle: "Your pre-authorized signature for this activity",
                                    isSigning: $isPreApprovedSigning,
                                    clearSignature: $clearPreApprovedSignature,
                                    signatureImage: $preApprovedSignatureImage,
                                    signaturePNGData: $preApprovedSignaturePNGData,
                                    previousSignatureURL: previousPreAprrovedSignatureURL
                                )
                            }
                        }
                    }
                    
                    // Status Message
                    if let statusMessage = submissionStatusMessage {
                        StatusMessageView(
                            message: statusMessage,
                            isError: isError
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: DSSpacing.md) {
                        DSButton("Save Progress") {
                            Task {
                                if let previousSubmission = submissionToEdit {
                                    await saveprogress(previousSubmissionId: previousSubmission.id)
                                } else {
                                    await saveprogress()
                                }
                            }
                        }
                        .buttonStyle(.secondary)
                        .buttonSize(.large)
                        .fullWidth()
                        .loading(isLoading)
                        .enabled(!isLoading)
                        
                        DSButton("Submit Hours") {
                            Task {
                                if previousSubmissionExists {
                                    await submitForm(previousSubmissionId: submissionToEdit?.id)
                                } else {
                                    await submitForm()
                                }
                            }
                        }
                        .buttonStyle(.primary)
                        .buttonSize(.large)
                        .fullWidth()
                        .loading(isLoading)
                        .enabled(!isLoading && allFieldsValid && signaturesComplete)
                        
                        if !allFieldsValid || !signaturesComplete {
                            VStack(spacing: DSSpacing.xs) {
                                if !allFieldsValid {
                                    Text("• Complete all required fields")
                                        .font(DSTypography.caption)
                                        .foregroundColor(DSColor.statusWarning)
                                }
                                if !signaturesComplete {
                                    Text("• Provide both required signatures")
                                        .font(DSTypography.caption)
                                        .foregroundColor(DSColor.statusWarning)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer(minLength: DSSpacing.xxl)
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.xl)
            }
            .background(DSColor.backgroundSecondary)
            .scrollDisabled(isAnySigning)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    DSButton("Done") {
                        focusedField = nil
                    }
                    .buttonStyle(.tertiary)
                    .buttonSize(.small)
                }
                
                if previousSubmissionExists {
                    ToolbarItem(placement: .topBarTrailing) {
                        DSIconButton(systemName: "trash", accessibilityLabel: "Delete submission") {
                            showingDeleteAlert = true
                        }
                        .buttonStyle(.destructive)
                        .loading(isDeleting)
                        .enabled(!isDeleting)
                    }
                }
            }
        }
        .task {
            if submissionToEdit != nil {
                await supervisorSignatureURL()
                await preApprovedSignatureURL()
                print("Existing submission: \(String(describing: submissionToEdit))")
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
    
    // MARK: - API Methods (unchanged)
    
    func supervisorSignatureURL() async {
        do {
            previousSupervisorSignatureURL = try await apiService.getSupervisorSignatureViewUrl(submissionId: submissionToEdit!.id)
        } catch {
            logger.log("Previous supervisor signature does not exist")
            previousSupervisorSignatureURL = nil
        }
    }
    
    func preApprovedSignatureURL() async  {
        do {
            previousPreAprrovedSignatureURL = try await apiService.getPreApprovedSignatureViewUrl(submissionId: submissionToEdit!.id)
        } catch {
            logger.log("Previous pre approved signature does not exist")
            previousPreAprrovedSignatureURL = nil
        }
    }
    
    func isFormValid() -> Bool {
        guard !orgName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !hoursString.isEmpty else { return false }
        guard let hours = Double(hoursString), hours > 0 else { return false }
        
        return true
    }
    
    private func cancelSupervisorSigning() {
        isSupervisorSigning = false
    }
    
    private func cancelPreApprovedSigning() {
        isPreApprovedSigning = false
    }
    
    private func saveprogress(previousSubmissionId: String? = nil) async {
        isLoading = true
        isError = false
        
        let dateString = AppDateFormatter.isoDateFormatter.string(from: submissionDate)
        
        let submissionDTO = CreateSubmissionDto(
            orgName: orgName,
            hours: Double(hoursString),
            telephone: Double(telephone),
            supervisorName: supervisorName,
            submissionDate: dateString,
            status: "DRAFT",
            description: description.isEmpty ? nil : description
        )
        
        do {
            logger.info("Step 1: updating submission record...")
            var submissionId: String
            print("checkign id of submission we're sending \(String(describing: previousSubmissionId))")
            if previousSubmissionExists && (previousSubmissionId != nil) {
                let updatedSubmission = try await apiService.updateSubmission(submissionId: previousSubmissionId!, existingSubmission: submissionDTO)
                submissionId = updatedSubmission.id
            } else {
                let newIncompleteSubmission = try await apiService.submitHours(submissionData: submissionDTO)
                submissionId = newIncompleteSubmission.id
            }
            
            logger.info("Step 1 Successful! Submission ID: \(submissionId)")
            submissionStatusMessage = "Record updated, preparing signature upload..."
            
            
            if let supervisorSignaturePNG = supervisorSignaturePNGData {
                // --- Step 2: Get S3 upload URL ---
                logger.info("Step 2: Getting Supervisor signature upload URL...")
                let supervisorUploadInfo = try await apiService.getSupervisorSignatureUploadUrl(submissionId: submissionId)
                logger.info("Step 2 Successful! Got S3 key: \(supervisorUploadInfo.key)")
                submissionStatusMessage = "Uploading Supervisor signature..."
                
                
                
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
            }
            
            if let preApprovedSignaturePNG = preApprovedSignaturePNGData {
                // --- Step 2: Get S3 upload URL ---
                logger.info("Step 2: Getting Pre Approved signature upload URL...")
                let preApprovedIploadInfo = try await apiService.getPreApprovedSignatureUploadUrl(submissionId: submissionId)
                logger.info("Step 2 Successful! Got S3 key: \(preApprovedIploadInfo.key)")
                submissionStatusMessage = "Uploading Pre Approved signature..."
                
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
                
            }
            
            // --- Final Success ---
            submissionStatusMessage = "Submission complete!"
            isError = false
            await viewModel.fetchUserSubmissions()
            // Wait briefly so user sees success message, then dismiss
            try? await Task.sleep(nanoseconds: 500_000_000) // 1.5 seconds
            dismiss() // Dismiss the sheet
        } catch {
            isLoading = false
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
    
    
    private func submitForm(previousSubmissionId: String? = nil) async {
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
        
        guard let telephoneConverted = Double(telephone) else {
            isError = true
            submissionStatusMessage = "Please fill in valid telephone number"
            return
        }
        
        guard supervisorSignaturePNGData != nil || previousSupervisorSignatureURL != nil else {
            submissionStatusMessage = "Supervisor Signature is missing."
            isError = true
            return
        }
        
        guard preApprovedSignaturePNGData != nil || previousPreAprrovedSignatureURL != nil else {
            submissionStatusMessage = "Pre Approved Signature is missing."
            isError = true
            return
        }
        
        isLoading = true
        isError = false
        print("Date format before transformation \(submissionDate)")
        let dateString = AppDateFormatter.isoDateFormatter.string(from: submissionDate)
        
        let initialSubmissionDTO = CreateSubmissionDto(
            orgName: orgName,
            hours: hours,
            telephone: telephoneConverted,
            supervisorName: supervisorName,
            submissionDate: dateString,
            status: "SUBMITTED",
            description: description.isEmpty ? nil : description
        )
        
        print("Date being sent to backend: \(dateString)")
        do {
            var submissionId: String
            // --- Step 1: Create initial submission record ---
            logger.info("Step 1: Creating initial submission record...")
            
            if previousSubmissionExists && (previousSubmissionId != nil) {
                let updatedSubmission = try await apiService.updateSubmission(submissionId: previousSubmissionId!, existingSubmission: initialSubmissionDTO)
                submissionId = updatedSubmission.id
            } else {
                let newIncompleteSubmission = try await apiService.submitHours(submissionData: initialSubmissionDTO)
                submissionId = newIncompleteSubmission.id
            }
            
            
            logger.info("Step 1 Successful! Submission ID: \(submissionId)")
            submissionStatusMessage = "Record created, preparing signature upload..."
            
            if previousSupervisorSignatureURL == nil {
                guard let supervisorSignaturePNG = supervisorSignaturePNGData else {
                    logger.error("Supervisor Signature not found!")
                    return
                }
                
                // --- Step 2: Get S3 upload URL ---
                logger.info("Step 2: Getting Supervisor signature upload URL...")
                let supervisorUploadInfo = try await apiService.getSupervisorSignatureUploadUrl(submissionId: submissionId)
                logger.info("Step 2 Successful! Got S3 key: \(supervisorUploadInfo.key)")
                submissionStatusMessage = "Uploading Supervisor signature..."
                
                
                
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
            }
            
            if previousPreAprrovedSignatureURL == nil {
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
            }
            
            // --- Final Success ---
            submissionStatusMessage = "Submission complete!"
            isError = false
            await viewModel.fetchUserSubmissions()
            // Wait briefly so user sees success message, then dismiss
            try? await Task.sleep(nanoseconds: 500_000_000) // 1.5 seconds
            dismiss() // Dismiss the sheet
            
        } catch {
            isLoading = false
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
    
    private func deleteSubmission() async {
        isDeleting = true
        deleteError = nil
        
        do {
            if let submission = submissionToEdit {
                try await apiService.deleteSubmission(submissionId: submission.id)
                logger.info("Successfully deleted submission \(submission.id)")
            }
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

// MARK: - Supporting Views

struct FormProgressView: View {
    let formComplete: Bool
    let signaturesComplete: Bool
    
    var body: some View {
        HStack(spacing: DSSpacing.xl) {
            ProgressStepView(
                title: "Form Details",
                isComplete: formComplete,
                icon: "doc.text.fill"
            )
            
            Rectangle()
                .fill(DSColor.border)
                .frame(height: 2)
                .frame(maxWidth: 40)
            
            ProgressStepView(
                title: "Signatures",
                isComplete: signaturesComplete,
                icon: "signature"
            )
        }
        .padding(DSSpacing.lg)
        .background(DSColor.backgroundSecondary)
        .cornerRadius(DSRadius.md)
    }
}

struct ProgressStepView: View {
    let title: String
    let isComplete: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            ZStack {
                Circle()
                    .fill(isComplete ? DSColor.statusSuccess : DSColor.backgroundSecondary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isComplete ? DSColor.statusSuccess : DSColor.border, lineWidth: 2)
                    )
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(DSColor.textOnPrimary)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(DSColor.textSecondary)
                }
            }
            
            Text(title)
                .font(DSTypography.caption)
                .foregroundColor(isComplete ? DSColor.statusSuccess : DSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(DSColor.accent)
                    .font(.title3.weight(.semibold))
                
                Text(title)
                    .font(DSTypography.headline)
                    .foregroundColor(DSColor.textPrimary)
                
                Spacer()
            }
            
            content
        }
        .padding(DSSpacing.lg)
        .background(Color.white)
        .cornerRadius(DSRadius.md)
        .shadow(color: DSColor.textPrimary.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct SignatureInputView: View {
    let title: String
    let subtitle: String
    @Binding var isSigning: Bool
    @Binding var clearSignature: Bool
    @Binding var signatureImage: UIImage?
    @Binding var signaturePNGData: Data?
    let previousSignatureURL: URL?
    
    var isComplete: Bool {
        return signaturePNGData != nil || previousSignatureURL != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(title)
                        .font(DSTypography.bodyMedium)
                        .foregroundColor(DSColor.textPrimary)
                    
                    Text(subtitle)
                        .font(DSTypography.caption)
                        .foregroundColor(DSColor.textSecondary)
                }
                
                Spacer()
                
                if isComplete {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DSColor.statusSuccess)
                            .font(.caption)
                        
                        Text("Complete")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.statusSuccess)
                    }
                }
            }
            
            // Signature Area
            if previousSignatureURL == nil {
                SignaturePadView(
                    title: title.contains("Supervisor") ? "Supervisor" : "Pre-Approved",
                    isSigning: $isSigning,
                    clearSignature: $clearSignature,
                    signatureImage: $signatureImage,
                    signaturePNGData: $signaturePNGData
                )
                .frame(height: 120)
                .background(Color.white)
                .cornerRadius(DSRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .stroke(isComplete ? DSColor.statusSuccess : DSColor.border, lineWidth: isComplete ? 2 : 1)
                )
            } else {
                AsyncImage(url: previousSignatureURL) { phase in
                    switch phase {
                    case .empty:
                        DSProgressScreen()
                            .frame(height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .background(Color.white)
                            .cornerRadius(DSRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.md)
                                    .stroke(DSColor.statusSuccess, lineWidth: 2)
                            )
                    case .failure:
                        VStack(spacing: DSSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DSColor.statusWarning)
                                .font(.title3)
                            Text("Could not load signature")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColor.textSecondary)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(DSColor.backgroundSecondary.opacity(0.5))
                        .cornerRadius(DSRadius.md)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(DSSpacing.md)
        .background(isComplete ? DSColor.statusSuccess.opacity(0.05) : DSColor.backgroundSecondary)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(isComplete ? DSColor.statusSuccess.opacity(0.3) : DSColor.border, lineWidth: 1)
        )
    }
}

struct SigningModeBar: View {
    @Binding var isSupervisorSigning: Bool
    @Binding var isPreApprovedSigning: Bool
    let onCancelSupervisor: () -> Void
    let onCancelPreApproved: () -> Void
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "hand.draw.fill")
                    .foregroundColor(DSColor.accent)
                    .font(.title3)
                
                Text("Signature Mode Active")
                    .font(DSTypography.headline)
                    .foregroundColor(DSColor.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: DSSpacing.md) {
                if isSupervisorSigning {
                    DSButton("Complete Supervisor") {
                        isSupervisorSigning = false
                    }
                    .buttonStyle(.primary)
                    .buttonSize(.small)
                }
                
                if isPreApprovedSigning {
                    DSButton("Complete Pre-Approved") {
                        isPreApprovedSigning = false
                    }
                    .buttonStyle(.primary)
                    .buttonSize(.small)
                }
                
                Spacer()
            }
            
            Text("You can continue editing while signing. Tap 'Complete' when finished.")
                .font(DSTypography.caption)
                .foregroundColor(DSColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DSSpacing.lg)
        .background(DSColor.accent.opacity(0.1))
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(DSColor.accent.opacity(0.3), lineWidth: 1)
        )
    }
}
