import SwiftUI
import Clerk
import os.log

//struct HomeView: View {
//    @StateObject private var viewModel = HomeViewModel()
//    @State var selectedMenuItem: MenuNavigation = .submissions
//    
//    private var screenWidth: CGFloat {
//        UIScreen.main.bounds.width
//    }
//    private var menuWidth: CGFloat {
//        0.75 * screenWidth
//    }
//    @State private var isMenuOpen: Bool = false
//    
//    // Access Clerk from the environment to allow signing out
//    @Environment(Clerk.self) private var clerk
//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HomeView")
//    
//    var body: some View {
//        ZStack {
//            NavigationStack {
//                Group {
//                    switch selectedMenuItem {
//                    case .submissions:
//                        SubmissionsView(viewModel: viewModel, isMenuOpen: $isMenuOpen)
//                    case .userinfo:
//                        UserInfoView(viewModel: viewModel)
//                    case .exportPDF:
//                        ExportView(viewModel: viewModel)
//                    }
//                }
//                
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button {
//                            withAnimation(.easeInOut) {
//                                isMenuOpen = true
//                            }
//                        } label: {
//                            Image(systemName: "line.3.horizontal")
//                                .foregroundStyle(DSColor.accent)
//                        }
//                    }
//                    
//                    // Top Right "+" Button
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        DSIcons.addSubmission
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 24, height: 24)
//                            .onTapGesture {
//                                viewModel.showingSubmitSheet = true
//                            }
//                            
//                    }
//                }
//                .navigationDestination(isPresented: $viewModel.showingSubmitSheet) {
//                    SubmissionFormView()
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .offset(x: isMenuOpen ? menuWidth * 0.3 : 0)
//            .zIndex(0)
//            .task {
//                await getAndPrintTestToken()
//            }
//            
//            
//            if isMenuOpen {
//                Color.black.opacity(0.4)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//                    .ignoresSafeArea(.all, edges: .vertical)
//                    .offset(x: isMenuOpen ? menuWidth * 0.3 : 0)
//                    .zIndex(0)
//                    .onTapGesture {
//                        withAnimation(.easeInOut) {
//                            isMenuOpen = false
//                        }
//                    }
//                    .animation(.easeInOut, value: isMenuOpen)
//            }
//            HStack {
//                MenuView(selectedMenuItem: $selectedMenuItem, isMenuOpen: $isMenuOpen)
//                    .frame(width: menuWidth)
//                Spacer()
//            }
//            
//            .offset(x: isMenuOpen ? 0 : -menuWidth)
//            .allowsHitTesting(isMenuOpen)
//            .ignoresSafeArea(.all, edges: .vertical)
//        }
//    }
//    
//    func getAndPrintTestToken() async {
//        guard let session = clerk.session else {
//            print("Error with session fetch... :(")
//            return
//        }
//        
//        let tokenOptions = Session.GetTokenOptions(template: "reacttest")
//        
//        do {
//            let catchToken = try  await session.getToken(tokenOptions)
//            print("Token: \(catchToken)")
//        } catch {
//            print("error trying to fetch token: \(error)")
//        }
//    }
//}
//
// MARK: - Option 1: Card-Style with Better Visual Hierarchy

struct SubmissionRow: View {
    let submission: SubmissionResponse
    
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            // Header row with org name and hours
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(submission.orgName ?? "Organization name not provided")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(submission.submissionDate, formatter: Self.dateFormatter)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
                
                Spacer()
                
                // Hours badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(submission.hours ?? 0, specifier: "%.1f")")
                        .font(DSTypography.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(DSColor.accent)
                    
                    Text("hours")
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            
                HStack {
                    Circle()
                        .fill(statusColor(submission.status))
                        .frame(width: 8, height: 8)
                    
                    Text(submission.status.capitalized)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textSecondary)
                    
                    Spacer()
                }
    
        }
        .padding(DSSpacing.md)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "APPROVED": return DSColor.statusSuccess
        case "REJECTED": return DSColor.statusError
        case "SUBMITTED": return DSColor.statusWarning
        default: return DSColor.statusWarning
        }
    }
}
//
//enum MenuNavigation {
//    case submissions
//    case userinfo
//    case exportPDF
//}
