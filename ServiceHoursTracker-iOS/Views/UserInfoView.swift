//
//  UserInfoView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI
import os.log

struct UserInfoView: View {
    @ObservedObject var viewModel: HomeViewModel
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UserInfoView")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with profile image
                HStack {
                    Circle()
                        .fill(DSColor.backgroundSecondary)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(initialsFromName)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(DSColor.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userProfile?.name ?? "Loading...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(DSColor.textPrimary)
                        
                        Text(viewModel.userProfile?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.textSecondary)
                    }
                    
                }
                .padding(.bottom)
                
                // User Information Sections
                userInfoSection(
                    title: "School Information",
                    items: [
                        ("Student ID", viewModel.userProfile?.oen ?? "Not provided", "number"),
                        ("School ID", viewModel.userProfile?.schoolId ?? "Not provided", "building.2"),
                        ("Principal", viewModel.userProfile?.principal ?? "Not provided", "person.bust")
                    ]
                )
                
                userInfoSection(
                    title: "Personal Information",
                    items: [
                        ("Date of Birth", formatDate(viewModel.userProfile?.dateOfBirth), "calendar"),
                        ("Account Created", formatDate(viewModel.userProfile?.createdAt), "clock")
                    ]
                )
                
                userInfoSection(
                    title: "Signatures",
                    items: [
                        ("Student Signature", viewModel.userProfile?.studentSignatureUrl != nil ? "Provided" : "Not provided", "signature"),
                        ("Parent Signature", viewModel.userProfile?.parentSignatureUrl != nil ? "Provided" : "Not provided", "signature")
                    ]
                )
                
                if viewModel.isLoadingProfile {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                if let error = viewModel.profileError {
                    Text(error)
                        .foregroundColor(DSColor.statusError)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile()
        }
    }
    
    // Helper Views
    private func userInfoSection(title: String, items: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(DSColor.accent)
            
            VStack(spacing: 16) {
                ForEach(items, id: \.0) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.2)
                            .foregroundColor(DSColor.accent.opacity(0.8))
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.0)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.textSecondary)
                            
                            Text(item.1)
                                .font(.body)
                                .foregroundStyle(DSColor.textPrimary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(DSColor.backgroundSecondary)
            .cornerRadius(12)
        }
    }
    
    // Helper computed properties and functions
    private var initialsFromName: String {
        guard let name = viewModel.userProfile?.name else { return "?" }
        
        let components = name.components(separatedBy: " ")
        if components.count >= 2,
           let firstInitial = components.first?.first,
           let lastInitial = components.last?.first {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = name.first {
            return "\(firstInitial)"
        }
        
        return "?"
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not provided" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date)
    }
}
