//
//  ToolBarHelpers.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-08.
//

import SwiftUI

// MARK: - Main Shared Toolbar
@MainActor
@ToolbarContentBuilder
func sharedToolbarItems(currentTab: TabIdentifier, coordinator: NavigationCoordinator) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
        Button {
            coordinator.navigateToRoute(.recordSubmission, in: currentTab)
        } label: {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundColor(DSColor.accent)
        }
        .accessibilityLabel("Add Submission")
    }
    
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            coordinator.navigateToRoute(.userProfile, in: currentTab)
        } label: {
            Image(systemName: "person")
                .font(.title2)
                .foregroundColor(DSColor.accent)
        }
        .accessibilityLabel("User Profile")
    }
}
