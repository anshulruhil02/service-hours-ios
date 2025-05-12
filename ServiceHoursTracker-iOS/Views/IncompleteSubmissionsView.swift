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
            if viewModel.isLoading && viewModel.incompleteSubmissions.isEmpty {
                ProgressView("Loading your hours...")
                    .foregroundStyle(DSColor.textSecondary)
                    .tint(DSColor.accent)
                    .padding(.top, 50)
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(DSColor.statusWarning)
                    Text("Error Loading Data")
                        .font(.headline)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DSColor.textSecondary)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task { await viewModel.fetchUserSubmissions() }
                    }
                    .buttonStyle(.bordered)
                    .tint(DSColor.accent)
                    .padding(.top)
                    Spacer()
                }
                .padding()
            } else {
                VStack {
                    List {
                        if viewModel.incompleteSubmissions.isEmpty {
                            Text("No submissions logged yet.\nTap the '+' button to add your first entry.")
                                .foregroundStyle(DSColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 50)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(viewModel.incompleteSubmissions) { submission in
                                NavigationLink {
                                    SubmissionFormView(existingSubmission: submission)
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
                    .task {
                        await viewModel.fetchUserSubmissions()
                    }
                }
            }
        }
    }
}
