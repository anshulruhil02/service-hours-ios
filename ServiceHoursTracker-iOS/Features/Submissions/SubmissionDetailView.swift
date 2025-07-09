//
//  SubmissionDetailView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-05.
//

import SwiftUI
import os.log

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
    
    // Logger instance
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SubmissionDetailView")
    
    // Formatter for displaying the main submission date clearly
    private static var submissionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Formatter for displaying timestamps (created/updated)
    private static var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var submissionStatus: SubmissionStatus {
        // You can extend this based on your actual status logic
        if submission.hours != nil && submission.orgName != nil {
            return .completed
        } else {
            return .draft
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                // Header Section with Status
                SubmissionHeaderView(
                    submission: submission,
                    status: submissionStatus
                )
                
                // Service Details Section
                DetailSection(title: "Service Details", icon: "briefcase.fill") {
                    VStack(spacing: DSSpacing.lg) {
                        DetailInfoCard(
                            icon: "building.2.fill",
                            label: "Organization",
                            value: submission.orgName ?? "Not specified",
                            accentColor: DSColor.accent
                        )
                        
                        HStack(spacing: DSSpacing.md) {
                            DetailInfoCard(
                                icon: "clock.fill",
                                label: "Hours",
                                value: String(format: "%.1f", submission.hours ?? 0),
                                accentColor: DSColor.statusSuccess
                            )
                            
                            DetailInfoCard(
                                icon: "phone.fill",
                                label: "Contact",
                                value: formatPhoneNumber(submission.telephone),
                                accentColor: DSColor.statusInfo
                            )
                        }
                        
                        DetailInfoCard(
                            icon: "person.crop.circle.fill",
                            label: "Supervisor",
                            value: submission.supervisorName ?? "Not specified",
                            accentColor: DSColor.secondary
                        )
                        
                        DetailInfoCard(
                            icon: "calendar",
                            label: "Date Completed",
                            value: Self.submissionDateFormatter.string(from: submission.submissionDate),
                            accentColor: DSColor.accent
                        )
                    }
                }
                
                // Description Section (if exists)
                if let description = submission.description, !description.isEmpty {
                    DetailSection(title: "Description", icon: "text.alignleft") {
                        Text(description)
                            .font(DSTypography.body)
                            .foregroundColor(DSColor.textPrimary)
                            .padding(DSSpacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(DSRadius.md)
                    }
                }
                
                // Signatures Section
                DetailSection(title: "Digital Signatures", icon: "signature") {
                    VStack(spacing: DSSpacing.lg) {
                        SignatureDisplayView(
                            title: "Supervisor Signature",
                            subtitle: "Verified by supervising staff",
                            signatureUrl: supervisorSignatureViewUrl,
                            isLoading: supervisorIsLoadingSignature,
                            error: supervisorSignatureError
                        )
                        
                        SignatureDisplayView(
                            title: "Pre-Approved Signature",
                            subtitle: "Student pre-authorization",
                            signatureUrl: preApprovedSignatureViewUrl,
                            isLoading: preApprovedIsLoadingSignature,
                            error: preApprovedSignatureError
                        )
                    }
                }
                
                // Metadata Section
                DetailSection(title: "Record Information", icon: "info.circle.fill") {
                    VStack(spacing: DSSpacing.md) {
                        MetadataRow(
                            icon: "calendar.badge.plus",
                            label: "Submitted",
                            value: Self.timestampFormatter.string(from: submission.createdAt)
                        )
                        
                        MetadataRow(
                            icon: "pencil.circle",
                            label: "Last Updated",
                            value: Self.timestampFormatter.string(from: submission.updatedAt)
                        )
                        
                        MetadataRow(
                            icon: "number",
                            label: "Record ID",
                            value: submission.id,
                            isMonospace: true
                        )
                    }
                    .padding(DSSpacing.lg)
                    .background(DSColor.backgroundSecondary.opacity(0.5))
                    .cornerRadius(DSRadius.md)
                }
                
                Spacer(minLength: DSSpacing.xxl)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.xl)
        }
        .background(DSColor.backgroundSecondary)
        .navigationTitle("Service Record")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if supervisorSignatureViewUrl == nil && !supervisorIsLoadingSignature && supervisorSignatureError == nil {
                await loadSupervisorSignatureUrl()
            }
            
            if preApprovedSignatureViewUrl == nil && !preApprovedIsLoadingSignature && preApprovedSignatureError == nil {
                await loadPreApprovedSignatureUrl()
            }
        }
    }
    
    private func formatPhoneNumber(_ phone: Double?) -> String {
        guard let phone = phone else { return "Not provided" }
        let phoneString = String(format: "%.0f", phone)
        
        // Basic phone number formatting (you can enhance this)
        if phoneString.count == 10 {
            let formatted = phoneString.prefix(3) + "-" + phoneString.dropFirst(3).prefix(3) + "-" + phoneString.suffix(4)
            return String(formatted)
        }
        return phoneString
    }
    
    // MARK: - API Methods (unchanged)
    
    func loadSupervisorSignatureUrl() async {
        supervisorIsLoadingSignature = true
        supervisorSignatureError = nil
        logger.info("Fetching signature view URL for submission \(submission.id)")
        
        do {
            let result = try await apiService.getSupervisorSignatureViewUrl(submissionId: submission.id)
            print("Signature fetching result: \(String(describing: result))")
            supervisorSignatureViewUrl = result
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
            print("Signature fetching result: \(String(describing: result))")
            preApprovedSignatureViewUrl = result
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

// MARK: - Supporting Views

enum SubmissionStatus {
    case draft
    case completed
    case approved
    
    var color: Color {
        switch self {
        case .draft: return DSColor.statusWarning
        case .completed: return DSColor.statusSuccess
        case .approved: return DSColor.accent
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "pencil.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .approved: return "star.circle.fill"
        }
    }
    
    var text: String {
        switch self {
        case .draft: return "Draft"
        case .completed: return "Completed"
        case .approved: return "Approved"
        }
    }
}

struct SubmissionHeaderView: View {
    let submission: SubmissionResponse
    let status: SubmissionStatus
    
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            // Status Badge
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                    .font(.title3)
                
                Text(status.text)
                    .font(DSTypography.headline)
                    .foregroundColor(status.color)
                
                Spacer()
            }
            .padding(DSSpacing.lg)
            .background(status.color.opacity(0.1))
            .cornerRadius(DSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .stroke(status.color.opacity(0.3), lineWidth: 1)
            )
            
            // Main Details
            VStack(spacing: DSSpacing.md) {
                Text(submission.orgName ?? "Service Record")
                    .font(DSTypography.title)
                    .foregroundColor(DSColor.textPrimary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: DSSpacing.xl) {
                    QuickStatDetailView(
                        value: String(format: "%.1f", submission.hours ?? 0),
                        label: "Hours",
                        color: DSColor.statusSuccess
                    )
                    
                    QuickStatDetailView(
                        value: formatDateShort(submission.submissionDate),
                        label: "Completed",
                        color: DSColor.accent
                    )
                    
                    QuickStatDetailView(
                        value: submission.supervisorName?.components(separatedBy: " ").first ?? "N/A",
                        label: "Supervisor",
                        color: DSColor.secondary
                    )
                }
            }
        }
        .padding(DSSpacing.xl)
        .background(Color.white)
        .cornerRadius(DSRadius.md)
        .shadow(color: DSColor.textPrimary.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct QuickStatDetailView: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
            
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct DetailSection<Content: View>: View {
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
    }
}

struct DetailInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(accentColor)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(label)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColor.textSecondary)
                
                Text(value)
                    .font(DSTypography.bodyMedium)
                    .foregroundColor(DSColor.textPrimary)
            }
            
            Spacer()
        }
        .padding(DSSpacing.lg)
        .background(Color.white)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SignatureDisplayView: View {
    let title: String
    let subtitle: String
    let signatureUrl: URL?
    let isLoading: Bool
    let error: String?
    
    var hasSignature: Bool {
        return signatureUrl != nil
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
                
                if hasSignature && !isLoading && error == nil {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DSColor.statusSuccess)
                            .font(.caption)
                        
                        Text("Verified")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.statusSuccess)
                    }
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xs)
                    .background(DSColor.statusSuccess.opacity(0.1))
                    .cornerRadius(DSRadius.sm)
                }
            }
            
            // Signature Display Area
            ZStack {
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .fill(Color.white)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.md)
                            .stroke(hasSignature ? DSColor.statusSuccess : DSColor.border, lineWidth: hasSignature ? 2 : 1)
                    )
                
                if isLoading {
                    VStack(spacing: DSSpacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading signature...")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.textSecondary)
                    }
                } else if let url = signatureUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 120 - (DSSpacing.sm * 2))
                                .padding(DSSpacing.sm)
                        case .failure:
                            VStack(spacing: DSSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(DSColor.statusWarning)
                                    .font(.title3)
                                Text("Could not load signature")
                                    .font(DSTypography.caption)
                                    .foregroundColor(DSColor.textSecondary)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipped()
                } else if let errorMsg = error {
                    VStack(spacing: DSSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DSColor.statusError)
                            .font(.title3)
                        Text("Error: \(errorMsg)")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.statusError)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DSSpacing.md)
                } else {
                    VStack(spacing: DSSpacing.sm) {
                        Image(systemName: "signature")
                            .foregroundColor(DSColor.textSecondary.opacity(0.5))
                            .font(.title2)
                        Text("No signature provided")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.textSecondary)
                    }
                }
            }
        }
        .padding(DSSpacing.lg)
        .background(hasSignature ? DSColor.statusSuccess.opacity(0.05) : DSColor.backgroundSecondary)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(hasSignature ? DSColor.statusSuccess.opacity(0.3) : DSColor.border, lineWidth: 1)
        )
    }
}

struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    var isMonospace: Bool = false
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(DSColor.accent.opacity(0.7))
                .font(.caption)
                .frame(width: 16, height: 16)
            
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColor.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(isMonospace ? .system(.caption, design: .monospaced) : DSTypography.caption)
                .foregroundColor(DSColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
