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
            .background(DSColor.backgroundSecondary)
            .foregroundColor(DSColor.textPrimary)
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

enum Field: Hashable {
    case orgName, hours, telephone, supervisorName, description
}

struct SubmissionFormView: View {
    @State private var orgName: String = ""
    @State private var hoursString: String = "" // Collect hours as String for flexible input
    @State private var telephone: String = ""
    @State private var supervisorName: String = ""
    @State private var submissionDate: Date = Date() // Default to today
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
    @State var supervisorSignaturePDF: Data? = nil
    @State var supervisorSignaturePNGData: Data? = nil
    
    // states dealing with Pre Approved Signatures
    @State var isPreApprovedSigning: Bool = false
    @State var clearPreApprovedSignature: Bool = false
    @State var preApprovedSignatureImage: UIImage? = nil
    @State var preAppriovedSignaturePDF: Data? = nil
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
    
    @Environment(\.dismiss) var dismiss
    
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
        }
    }
    
    var body: some View {
        ZStack { // Apply global background
            DSColor.backgroundPrimary.ignoresSafeArea()
                .ignoresSafeArea()
            NavigationView {
                ScrollView {
                    VStack(alignment: .center, spacing: 10) {
                        TextField("Organization name", text: $orgName)
                            .focused($focusedField, equals: .orgName)
                            .dsInputFieldStyle()
                        
                        TextField("Hours completed", text: $hoursString)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .hours)
                            .dsInputFieldStyle()
                        
                        TextField("Telephone", text: $telephone)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .telephone)
                            .dsInputFieldStyle()
                        
                        TextField("Supervisor name", text: $supervisorName)
                            .focused($focusedField, equals: .supervisorName)
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
                                .focused($focusedField, equals: .description)
                                .foregroundColor(DSColor.textPrimary) // For typed text
                                .scrollContentBackground(.hidden)
                                .background(DSColor.backgroundSecondary) // Or DSColor.backgroundSurface
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DSColor.border, lineWidth:1))
                        }
                        .padding()
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    focusedField = nil
                                }
                            }
                        }
                        
                        HStack(spacing: 15) {
                            if previousSupervisorSignatureURL == nil {
                                SignaturePadView(
                                    title: "Supervisor",
                                    isSigning: $isSupervisorSigning,
                                    clearSignature: $clearSupervisorSignature,
                                    signatureImage: $supervisorSignatureImage,
                                    signaturePDF: $supervisorSignaturePDF,
                                    signaturePNGData: $supervisorSignaturePNGData
                                )
                                
                            } else {
                                VStack {
                                    Text("Supervisor signature")
                                        .foregroundStyle(DSColor.textPrimary)
                                    
                                    AsyncImage(url: previousSupervisorSignatureURL) { phase in
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
                            
                            if previousPreAprrovedSignatureURL == nil {
                                SignaturePadView(
                                    title: "Pre-Approved",
                                    isSigning: $isPreApprovedSigning,
                                    clearSignature: $clearPreApprovedSignature,
                                    signatureImage: $preApprovedSignatureImage,
                                    signaturePDF: $preAppriovedSignaturePDF, // Corrected typo in binding
                                    signaturePNGData: $preApprovedSignaturePNGData
                                )
                            } else {
                                VStack {
                                    Text("Pre-Approved signature")
                                        .foregroundStyle(DSColor.textPrimary)
                                    
                                    AsyncImage(url: previousPreAprrovedSignatureURL) { phase in
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
                        }
                        
                        
                        if let statusMessage = submissionStatusMessage {
                            Text(statusMessage)
                                .font(.caption) // Consider DSFont.caption
                                .foregroundColor(isError ? DSColor.statusError : DSColor.statusSuccess)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 5)
                        }
                        
                        Section {
                            VStack{
                                
                                Button {
                                    Task {
                                        if let previousSubmission = submissionToEdit {
                                            await saveprogress(previousSubmissionId: previousSubmission.id)
                                        } else {
                                            await saveprogress()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isLoading {
                                            ProgressView()
                                        } else {
                                            Text("Save Progress")
                                                .fontWeight(.semibold)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(DSColor.primary)
                                .foregroundColor(DSColor.textOnPrimary)
                                .cornerRadius(8)
                                .controlSize(.large)
                                .disabled(isLoading)
                                
                                
                                Button {
                                    Task {
                                        if previousSubmissionExists {
                                            await submitForm(previousSubmissionId: submissionToEdit?.id)
                                        } else {
                                            await submitForm()
                                        }
                                    }
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
                                .controlSize(.large)
                            }
                        }
                    }
                    .padding()
                }
                .scrollDisabled(isAnySigning)
                .navigationTitle(previousSubmissionExists ? "Edit Service Hours" : "Log Service Hours")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            if submissionToEdit != nil {
                await supervisorSignatureURL()
                await preApprovedSignatureURL()
                print("Existing submission: \(String(describing: submissionToEdit))")
            }
        }
    }
    
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
    
    //    private func clearForm() {
    //        orgName = ""
    //        hoursString = ""
    //        submissionDate = Date() // Reset to today
    //        description = ""
    //        signatureImage = nil
    //        signaturePNGData = nil
    //    }
}
