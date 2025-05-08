// Views/HomeView.swift

import SwiftUI
import Clerk
import os.log

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    // Access Clerk from the environment to allow signing out
    @Environment(Clerk.self) private var clerk
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeView")

    var body: some View {
        // NavigationStack enables the navigation bar and pushing detail views (iOS 16+)
        NavigationStack {
            VStack {
                // Conditional content based on the ViewModel's state
                if viewModel.isLoading && viewModel.submissions.isEmpty {
                    // Show a loading indicator only when fetching initial data
                    ProgressView("Loading your hours...")
                        .padding(.top, 50) // Add some padding
                    Spacer() // Push indicator up
                } else if let errorMessage = viewModel.errorMessage {
                    // Display an error message if fetching failed
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error Loading Data")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task { await viewModel.fetchUserSubmissions() } // Allow user to retry
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                        Spacer() // Push error message up
                    }
                    .padding()
                } else {
                    VStack {
                        //                         --- Button to Get Test Token ---
                        Button("Get Test Token for Postman") {
                            Task {
                                await getAndPrintTestToken()
                            }
                        }
                        .buttonStyle(.bordered)
                        List {
                            if viewModel.submissions.isEmpty {
                                // Message shown when the list is empty
                                Text("No submissions logged yet.\nTap the '+' button to add your first entry.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 50)
                            } else {
                                // Loop through the fetched submissions from the ViewModel
                                ForEach(viewModel.submissions) { submission in
                                    // Each row is a NavigationLink to the detail view
                                    NavigationLink {
                                        // Destination view when a row is tapped
                                        SubmissionDetailView(submission: submission)
                                    } label: {
                                        // The content of the row itself
                                        SubmissionRow(submission: submission)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain) // Use plain style for the list
                        // Enable pull-to-refresh functionality
                        .refreshable {
                            logger.info("Pull to refresh triggered.")
                            await viewModel.fetchUserSubmissions() // Call fetch method on refresh
                        }
                    }
                }
            }
            .navigationTitle("My Hours") // Set the title displayed in the navigation bar
            // Add buttons to the navigation bar's toolbar
            .toolbar {
                // Top Left "Sign Out" Button
                ToolbarItem(placement: .navigationBarLeading) {
                     Button {
                         // Sign out asynchronously when tapped
                         Task {
                             do {
                                 try await clerk.signOut()
                                 logger.info("User signed out via button.")
                                 // The RootView's .onChange observer will handle navigation
                             } catch {
                                 logger.error("Sign out error: \(error.localizedDescription)")
                                 // Optionally show an alert for sign out errors
                             }
                         }
                     } label: {
                         // Use Text or an Image for the button
                         Text("Sign Out").foregroundColor(.red)
                     }
                }

                // Top Right "+" Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Set the ViewModel's state variable to true to present the sheet
                        viewModel.showingSubmitSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill") // Use a filled plus icon
                             .font(.title2) // Make the icon slightly larger
                    }
                }
            }
            // Modal Sheet Presentation for the Submission Form
            // This sheet appears when viewModel.showingSubmitSheet becomes true
            .sheet(isPresented: $viewModel.showingSubmitSheet) {
                // The view presented modally
                SubmissionFormView()
                // Code to run when the sheet is dismissed (e.g., user cancels or submits)
                 .onDisappear {
                      logger.info("SubmissionFormView sheet dismissed.")
                      // Re-fetch submissions when the sheet closes to ensure
                      // the list is up-to-date if a new submission was added.
                      Task { await viewModel.fetchUserSubmissions() }
                 }
            }
            // Fetch initial data when the view first appears
            .task {
                if viewModel.submissions.isEmpty {
                    logger.info("HomeView appeared, fetching initial submissions.")
                    await viewModel.fetchUserSubmissions()
                }
            }
        }
    }
    
    func getAndPrintTestToken() async {
        guard let session = clerk.session else {
            print("Error with session fetch... :(")
            return
        }
        
        let tokenOptions = Session.GetTokenOptions(template: "anshultest")
        
        do {
            let catchToken = try  await session.getToken(tokenOptions)
            print("Token: \(catchToken?.jwt)")
        } catch {
            print("error trying to fetch token: \(error)")
        }
    }

}

struct SubmissionRow: View {
    let submission: SubmissionResponse // Takes a submission object

    // Formatter for displaying dates concisely in the list
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // e.g., 4/25/25
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.orgName)
                    .font(.headline)
                    .lineLimit(1)
                Text("Date: \(submission.submissionDate, formatter: Self.dateFormatter)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer() // Pushes hours and status to the right
            
            VStack(alignment: .trailing) {
                 Text("\(submission.hours, specifier: "%.1f") hrs") // Format to 1 decimal place
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
//                 Text(submission.status.capitalized)
//                    .font(.caption)
//                    .fontWeight(.semibold)
//                    .padding(.horizontal, 6)
//                    .padding(.vertical, 2)
//                    .background(statusColor(submission.status).opacity(0.15)) // Slightly stronger background
//                    .foregroundColor(statusColor(submission.status))
//                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 6) // Add some vertical padding to rows
    }
    
    // Helper function to determine status color
     func statusColor(_ status: String) -> Color {
         switch status.lowercased() {
             case "approved": return .green
             case "rejected": return .red
             default: return .orange // pending
         }
     }
}

