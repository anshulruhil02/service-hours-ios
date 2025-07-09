//
//  UserInfoView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI
import os.log
import Clerk

struct UserInfoView: View {
    @Environment(Clerk.self) private var clerk
    @ObservedObject var viewModel: HomeViewModel
    @State private var isSigningOut = false
    @State private var showSignOutAlert = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UserInfoView")
    
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xxl) {
                // Profile Header Section
                ProfileHeaderView(userProfile: viewModel.userProfile)
                
                // Information Sections
                VStack(spacing: DSSpacing.xl) {
                    UserInfoSection(
                        title: "Academic Information",
                        icon: "graduationcap.fill",
                        items: [
                            InfoItem(label: "Student ID", value: viewModel.userProfile?.oen ?? "Not provided", icon: "number"),
                            InfoItem(label: "School ID", value: viewModel.userProfile?.schoolId ?? "Not provided", icon: "building.2.fill"),
                            InfoItem(label: "Principal", value: viewModel.userProfile?.principal ?? "Not provided", icon: "person.crop.circle.fill")
                        ]
                    )
                    
                    UserInfoSection(
                        title: "Personal Details",
                        icon: "person.fill",
                        items: [
                            InfoItem(label: "Date of Birth", value: formatDate(viewModel.userProfile?.dateOfBirth), icon: "calendar"),
                            InfoItem(label: "Account Created", value: formatDate(viewModel.userProfile?.createdAt), icon: "clock.fill")
                        ]
                    )
                    
                    UserInfoSection(
                        title: "Document Status",
                        icon: "doc.text.fill",
                        items: [
                            InfoItem(
                                label: "Student Signature",
                                value: viewModel.userProfile?.studentSignatureUrl != nil ? "Completed" : "Pending",
                                icon: "signature",
                                status: viewModel.userProfile?.studentSignatureUrl != nil ? .completed : .pending
                            ),
                            InfoItem(
                                label: "Parent Signature",
                                value: viewModel.userProfile?.parentSignatureUrl != nil ? "Completed" : "Pending",
                                icon: "signature",
                                status: viewModel.userProfile?.parentSignatureUrl != nil ? .completed : .pending
                            )
                        ]
                    )
                }
                
                // Sign Out Section
                VStack(spacing: DSSpacing.lg) {
                    DSButton("Sign Out") {
                        showSignOutAlert = true
                    }
                    .buttonStyle(.destructive)
                    .buttonSize(.large)
                    .leadingIcon(Image(systemName: "rectangle.portrait.and.arrow.right"))
                    .fullWidth()
                    .loading(isSigningOut)
                    .enabled(!isSigningOut)
                }
                .padding(.horizontal, DSSpacing.lg)
                
                // Loading and Error States
                if viewModel.isLoadingProfile {
                    LoadingStateView()
                }
                
                if let error = viewModel.profileError {
                    ErrorStateView(message: error)
                }
                
                Spacer(minLength: DSSpacing.xxl)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.xl)
        }
        .background(DSColor.backgroundSecondary)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            await viewModel.fetchUserProfile()
        }
    }
    
    // MARK: - Sign Out Function
    private func signOut() {
        isSigningOut = true
        
        Task {
            do {
                try await clerk.signOut()
                logger.info("User signed out successfully")
            } catch {
                logger.error("Failed to sign out: \(error.localizedDescription)")
                // Handle error if needed - could show an error alert
            }
            
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
    
    // Helper function for date formatting
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not provided" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views (unchanged)

struct ProfileHeaderView: View {
    
    let userProfile: UserResponse?
    
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [DSColor.accent.opacity(0.8), DSColor.accent]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: DSColor.accent.opacity(0.3), radius: 10, x: 0, y: 4)
                
                Text(initialsFromName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(DSColor.textOnPrimary)
            }
            
            // Profile Information
            VStack(spacing: DSSpacing.sm) {
                Text(userProfile?.name ?? "Loading...")
                    .font(DSTypography.title)
                    .foregroundColor(DSColor.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let email = userProfile?.email, !email.isEmpty {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(DSColor.accent)
                            .font(.caption)
                        
                        Text(email)
                            .font(DSTypography.subheadline)
                            .foregroundColor(DSColor.textSecondary)
                    }
                }
                
                // Quick stats
                if let profile = userProfile {
                    HStack(spacing: DSSpacing.xl) {
                        QuickStatView(
                            value: profile.studentSignatureUrl != nil ? "✓" : "○",
                            label: "Student Sig",
                            isComplete: profile.studentSignatureUrl != nil
                        )
                        
                        QuickStatView(
                            value: profile.parentSignatureUrl != nil ? "✓" : "○",
                            label: "Parent Sig",
                            isComplete: profile.parentSignatureUrl != nil
                        )
                        
                        QuickStatView(
                            value: formatMemberSince(profile.createdAt),
                            label: "Member Since",
                            isComplete: true
                        )
                    }
                    .padding(.top, DSSpacing.md)
                }
            }
        }
        .padding(DSSpacing.xl)
        .background(Color.white)
        .cornerRadius(DSRadius.md)
        .shadow(color: DSColor.textPrimary.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var initialsFromName: String {
        guard let name = userProfile?.name else { return "?" }
        
        let components = name.components(separatedBy: " ")
        if components.count >= 2,
           let firstInitial = components.first?.first,
           let lastInitial = components.last?.first {
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let firstInitial = name.first {
            return "\(firstInitial)".uppercased()
        }
        
        return "?"
    }
    
    private func formatMemberSince(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

struct QuickStatView: View {
    let value: String
    let label: String
    let isComplete: Bool
    
    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isComplete ? DSColor.statusSuccess : DSColor.textSecondary)
            
            Text(label)
                .font(DSTypography.caption)
                .foregroundColor(DSColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct UserInfoSection: View {
    let title: String
    let icon: String
    let items: [InfoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Section Header
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(DSColor.accent)
                    .font(.title3.weight(.semibold))
                
                Text(title)
                    .font(DSTypography.headline)
                    .foregroundColor(DSColor.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DSSpacing.lg)
            
            // Section Content
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    InfoItemRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.horizontal, DSSpacing.lg)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(DSRadius.md)
            .shadow(color: DSColor.textPrimary.opacity(0.05), radius: 4, x: 0, y: 1)
        }
    }
}

struct InfoItem {
    let label: String
    let value: String
    let icon: String
    let status: InfoStatus?
    
    init(label: String, value: String, icon: String, status: InfoStatus? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.status = status
    }
}

enum InfoStatus {
    case completed
    case pending
    case error
    
    var color: Color {
        switch self {
        case .completed: return DSColor.statusSuccess
        case .pending: return DSColor.statusWarning
        case .error: return DSColor.statusError
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct InfoItemRow: View {
    let item: InfoItem
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Leading Icon
            Image(systemName: item.icon)
                .foregroundColor(DSColor.accent.opacity(0.7))
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(item.label)
                    .font(DSTypography.subheadline)
                    .foregroundColor(DSColor.textSecondary)
                
                HStack(spacing: DSSpacing.sm) {
                    Text(item.value)
                        .font(DSTypography.bodyMedium)
                        .foregroundColor(DSColor.textPrimary)
                    
                    if let status = item.status {
                        Spacer()
                        
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: status.icon)
                                .foregroundColor(status.color)
                                .font(.caption)
                            
                            Text(status == .completed ? "Done" : status == .pending ? "Pending" : "Error")
                                .font(DSTypography.caption)
                                .foregroundColor(status.color)
                        }
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xs)
                        .background(status.color.opacity(0.1))
                        .cornerRadius(DSRadius.sm)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSProgressScreen()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: DSColor.accent))
            
            Text("Loading your profile...")
                .font(DSTypography.subheadline)
                .foregroundColor(DSColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
        .background(DSColor.backgroundSecondary)
        .cornerRadius(DSRadius.md)
    }
}

struct ErrorStateView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DSColor.statusError)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Error Loading Profile")
                    .font(DSTypography.bodyMedium)
                    .foregroundColor(DSColor.statusError)
                
                Text(message)
                    .font(DSTypography.caption)
                    .foregroundColor(DSColor.textSecondary)
            }
            
            Spacer()
        }
        .padding(DSSpacing.lg)
        .background(DSColor.statusError.opacity(0.1))
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(DSColor.statusError.opacity(0.3), lineWidth: 1)
        )
    }
}
