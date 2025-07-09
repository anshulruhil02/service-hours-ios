
//
//  HomeView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-08.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.lg) {
                Text("Service Hours Progress")
                    .font(DSTypography.thinTitle)
                    .foregroundColor(DSColor.textPrimary)
                
                ServiceHoursProgressView(
                    hoursApproved: viewModel.approvedHours,
                    hoursSubmitted: viewModel.submittedHours
                )
                .padding(.vertical)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Text("Complete your 40 hours of community service to fulfill your graduation requirements.")
                    .font(DSTypography.bodyMedium)
                    .foregroundColor(DSColor.textSecondary)
                
                HStack(spacing: DSSpacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(DSTypography.title)
                        .foregroundColor(DSColor.statusWarning)
                    
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Deadline")
                            .font(DSTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DSColor.textPrimary)
                        
                        Text("June 15, 2025")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DSSpacing.xs) {
                        Text("Time Remaining")
                            .font(DSTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DSColor.textPrimary)
                        
                        Text("10 months")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.statusWarning)
                    }
                }
                .padding(DSSpacing.lg)
                .background(DSColor.statusWarning.opacity(0.1))
                .cornerRadius(DSSpacing.md)
                
                Spacer()
            }
            .padding(DSSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
//            .onAppear {
//                Task {
//                    await viewModel.fetchUserSubmissions()
//                }
//            }
            .toolbar {
                sharedToolbarItems(currentTab: .homeTab, coordinator: nav)
            }
        }.background(DSColor.backgroundSecondary)
    }
}
