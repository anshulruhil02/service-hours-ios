//
//  IncompleteSubmissionsView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-09.
//

import SwiftUI

struct IncompleteSubmissionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        VStack {
            // Conditional content based on the ViewModel's state
            if viewModel.isLoading && viewModel.incompleteSubmissions.isEmpty {
                // Show a loading indicator only when fetching initial data
                ProgressView("Loading your hours...")
                    .foregroundStyle(DSColor.textSecondary)
                    .tint(DSColor.accent)
                    .padding(.top, DSSpacing.xxl)
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                // Display an error message if fetching failed
                VStack(spacing: DSSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(DSTypography.largeTitle)
                        .foregroundStyle(DSColor.statusWarning)
                    Text("Error Loading Data")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(errorMessage)
                        .font(DSTypography.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DSColor.textSecondary)
                        .padding(.horizontal, DSSpacing.lg)
                    Button("Retry") {
                        Task { await viewModel.fetchUserSubmissions() }
                    }
                    .buttonStyle(.bordered)
                    .tint(DSColor.accent)
                    .padding(.top, DSSpacing.sm)
                    Spacer()
                }
                .padding(DSSpacing.lg)
            } else {
                List {
                    if viewModel.incompleteSubmissions.isEmpty {
                        // Empty state inside the List
                        VStack(spacing: DSSpacing.lg) {
                            Image("Vector")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 500, height: 500) 
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DSSpacing.xxl * 2)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    } else {
                        Text("Your draft community service hours")
                            .font(DSTypography.subheadline)
                            .foregroundStyle(DSColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DSSpacing.md)
                            .padding(.vertical, DSSpacing.sm)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        // Loop through the fetched submissions from the ViewModel
                        ForEach(viewModel.incompleteSubmissions) { submission in
                            NavigationLink {
                                SubmissionFormView(existingSubmission: submission)
                                    .environmentObject(viewModel)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                SubmissionRow(submission: submission)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: DSSpacing.xs,
                                leading: DSSpacing.md,
                                bottom: DSSpacing.xs,
                                trailing: DSSpacing.md
                            ))
                        }
                    }
                }
                .background(DSColor.backgroundSecondary)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.fetchUserSubmissions()
                }
            }
        }
        .background(DSColor.backgroundSecondary)
    }
}
