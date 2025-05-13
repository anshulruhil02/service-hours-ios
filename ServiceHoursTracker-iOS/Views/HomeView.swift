import SwiftUI
import Clerk
import os.log

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State var selectedMenuItem: MenuNavigation = .submissions
    
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
        ZStack {
            DSColor.backgroundPrimary.ignoresSafeArea()
            NavigationStack {
                Group {
                    switch selectedMenuItem {
                    case .submissions:
                        SubmissionsView(viewModel: viewModel, isMenuOpen: $isMenuOpen)
                    case .userinfo:
                        UserInfoView(viewModel: viewModel)
                    case .exportPDF:
                        ExportView(viewModel: viewModel)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut) { // Add animation for menu toggle
                                isMenuOpen = true
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(DSColor.accent)
                        }
                    }
                    
                    // Top Right "+" Button
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.showingSubmitSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill") // Use a filled plus icon
                                .foregroundStyle(DSColor.accent) // Make the icon slightly larger
                        }
                    }
                }
                .navigationDestination(isPresented: $viewModel.showingSubmitSheet) {
                    SubmissionFormView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DSColor.backgroundPrimary.ignoresSafeArea())
            .offset(x: isMenuOpen ? menuWidth * 0.3 : 0)
            .zIndex(0) // Main content is at the base
            
            
            if isMenuOpen {
                Color.black.opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .ignoresSafeArea(.all, edges: .vertical)
                    .offset(x: isMenuOpen ? menuWidth * 0.3 : 0)
                    .zIndex(0)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
                    .animation(.easeInOut, value: isMenuOpen)
            }
            HStack {
                MenuView(selectedMenuItem: $selectedMenuItem, isMenuOpen: $isMenuOpen)
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

enum MenuNavigation {
    case submissions
    case userinfo
    case exportPDF
}
