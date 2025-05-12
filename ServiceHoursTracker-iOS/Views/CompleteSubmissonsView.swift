//
//  CompleteSubmissonsView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-09.
//

import SwiftUI

struct CompleteSubmissonsView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        VStack {
            // Conditional content based on the ViewModel's state
            if viewModel.isLoading && viewModel.completeSubmissions.isEmpty {
                // Show a loading indicator only when fetching initial data
                ProgressView("Loading your hours...")
                    .foregroundStyle(DSColor.textSecondary)
                    .tint(DSColor.accent)
                    .padding(.top, 50) // Add some padding
                Spacer() // Push indicator up
            } else if let errorMessage = viewModel.errorMessage {
                // Display an error message if fetching failed
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(DSColor.statusWarning)
                    Text("Error Loading Data")
                        .font(.headline)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(errorMessage)
                        .font(.caption) // Consider DSFont.caption
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DSColor.textSecondary)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task { await viewModel.fetchUserSubmissions() }
                    }
                    .buttonStyle(.bordered)
                    .tint(DSColor.accent)
                    .padding(.top)
                    Spacer() // Push error message up
                }
                .padding()
            } else {
                VStack {
                    List {
                        if viewModel.completeSubmissions.isEmpty {
                            // Message shown when the list is empty
                            Text("No submissions logged yet.\nTap the '+' button to add your first entry.")
                                .foregroundStyle(DSColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 50)
                                .listRowSeparator(.hidden)
                        } else {
                            // Loop through the fetched submissions from the ViewModel
                            ForEach(viewModel.completeSubmissions) { submission in
                                // Each row is a NavigationLink to the detail view
                                NavigationLink {
                                    SubmissionDetailView(submission: submission)
                                } label: {
                                    SubmissionRow(submission: submission)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchUserSubmissions()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchUserSubmissions()
        }
    }
}
