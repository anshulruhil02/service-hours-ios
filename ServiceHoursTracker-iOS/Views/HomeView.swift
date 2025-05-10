// Views/HomeView.swift

import SwiftUI
import Clerk
import os.log

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: TabIdentifier = .completeSubmissions
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    private var menuWidth: CGFloat {
        0.75 * screenWidth
    }
    @State private var isMenuOpen: Bool = false
    
    // Access Clerk from the environment to allow signing out
    @Environment(Clerk.self) private var clerk
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeView")
    
    var body: some View {
        // NavigationStack enables the navigation bar and pushing detail views (iOS 16+)
        ZStack {
            DSColor.backgroundPrimary.ignoresSafeArea()
            NavigationStack {
                TabView(selection: $selectedTab){
                    CompleteSubmissonsView(viewModel: viewModel)
                        .tabItem {
                            Label("Complete Submissions", systemImage: "checkmark.seal.text.page")
                        }
                        .tag(TabIdentifier.completeSubmissions)
                    
                    IncompleteSubmissionsView(viewModel: viewModel)
                        .tabItem {
                            Label("Incopmlete Submissions", systemImage: "chart.line.text.clipboard")
                        }
                        .tag(TabIdentifier.incompleteSubmissions)
                }
                .navigationTitle("My Hours") // Set the title displayed in the navigation bar
                // Add buttons to the navigation bar's toolbar
//                .onTapGesture {
//                    withAnimation(.easeInOut) {
//                        isMenuOpen = false
//                    }
//                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut) { // Add animation for menu toggle
                                isMenuOpen.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(DSColor.accent)
                        }
                    }
                    
                    // Top Right "+" Button
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // Set the ViewModel's state variable to true to present the sheet
                            viewModel.showingSubmitSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill") // Use a filled plus icon
                                .foregroundStyle(DSColor.accent) // Make the icon slightly larger
                        }
                    }
                }
                .navigationDestination(isPresented: $viewModel.showingSubmitSheet) {
                    SubmissionFormView()
                        .onDisappear {
                            logger.info("SubmissionFormView sheet dismissed.")
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
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills space
            .background(DSColor.backgroundPrimary.ignoresSafeArea()) // Background for the main content area
            .offset(x: isMenuOpen ? menuWidth * 0.3 : 0) // Optional: Slight push effect for main content
            .disabled(isMenuOpen) // Disable main content interaction when menu is open
            .zIndex(0) // Main content is at the base
            
            // Layer 2: Dimming Overlay (Only appears when menu is open)
            if isMenuOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle()) // Ensure the whole area is tappable
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
                    .zIndex(1) // Above main content, below menu
            }
            HStack {
                MenuView()
                    .frame(width: menuWidth)
                // Slide in/out
                Spacer() // Pushes menu to the left
            }
            .offset(x: isMenuOpen ? 0 : -menuWidth)
            .allowsHitTesting(isMenuOpen)
            .ignoresSafeArea(.all, edges: .vertical)
        }
    }
}

enum TabIdentifier {
    case completeSubmissions
    case incompleteSubmissions
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
                Text(submission.orgName ?? "Organization name not provided")
                    .foregroundStyle(DSColor.textPrimary)
                    .font(.headline)
                    .lineLimit(1)
                Text("Date: \(submission.submissionDate, formatter: Self.dateFormatter)")
                    .font(.subheadline)
                    .foregroundStyle(DSColor.accent)
            }
            Spacer() // Pushes hours and status to the right
            
            VStack(alignment: .trailing) {
                Text("\(submission.hours ?? 0, specifier: "%.1f") hrs") // Format to 1 decimal place
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(DSColor.textPrimary)
            }
        }
        .padding(.vertical, 6)
//        .background(DSColor.backgroundSecondary)
    }
    
    // Helper function to determine status color
    func statusDSColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "approved": return DSColor.statusSuccess
        case "rejected": return DSColor.statusError
        default: return DSColor.statusWarning // for pending or other statuses
        }
    }
}

