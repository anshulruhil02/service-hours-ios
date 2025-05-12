//
//  MenuView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-10.
//

import SwiftUI
import os.log
import Clerk

struct MenuView: View {
    @Environment(Clerk.self) private var clerk // For Clerk operations
    // If you need to close the menu from within, you might pass isMenuOpen as a @Binding
    // @Binding var isMenuOpen: Bool // Example
    @Binding var selectedMenuItem: MenuNavigation
    @Binding var isMenuOpen: Bool
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "MenuView")
    
    var body: some View {
        // The ZStack's main purpose here is to set the background
        // that ignores safe areas for the menu's content area.
        // The frame of this ZStack (width) will be determined by HomeView.
        NavigationStack {
            ZStack {
                DSColor.backgroundSecondary
                    .ignoresSafeArea() // Make background fill the menu's allocated space
                
                VStack(alignment: .leading, spacing: 0) { // spacing 0, control with padding or Spacer
                    
                    // 1. Header Section (Optional, but nice)
                    MenuHeaderView()
                        .padding(.bottom, 20)
                    
                    // 2. Menu Items
                    MenuItem(iconName: "list.bullet.rectangle.portrait.fill", title: "Submissions") {
                        logger.info("Submissions tapped")
                        selectedMenuItem = .submissions
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
                    
                    MenuDivider()
                    
                    MenuItem(iconName: "person.circle.fill", title: "User Info") {
                        logger.info("User info tapped")
                        selectedMenuItem = .userinfo
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
                    
                    MenuDivider()
                    
                    MenuItem(iconName: "square.and.arrow.down", title: "Export PDF") {
//                        print("Menu Tapped")
//                        Task { await viewModel.generateAndPreparePdfReport() }
//                        //                    Button {
//                        //                        Task { await viewModel.generateAndPreparePdfReport() }
//                        //                    } label: {
//                        //                        Label("Download Report", systemImage: "doc.text.fill")
//                        //                    }
                        selectedMenuItem = .exportPDF
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
                    
                    // Add more menu items here if needed, each followed by a MenuDivider
                    // MenuItem(iconName: "gearshape.fill", title: "Settings") { ... }
                    // MenuDivider()
                    
                    Spacer() // Pushes the Sign Out button to the bottom
                    
                    // 3. Footer / Sign Out Section
                    MenuDivider()
                    
                    MenuItem(iconName: "arrow.left.square.fill", title: "Sign Out", role: .destructive) {
                        logger.info("Sign out tapped")
                        Task {
                            do {
                                // Ensure you are using the correct sign out method for your Clerk SDK version
                                // For ClerkSwift 2.0+ it's usually clerk.client.signOut()
                                try await clerk.signOut()
                                logger.info("User signed out successfully.")
                                // IMPORTANT: After sign out, you need to notify your app's root
                                // to switch to the login screen. This often involves changing
                                // an @ObservedObject or @EnvironmentObject's state.
                            } catch {
                                logger.error("Sign out error: \(error.localizedDescription)")
                                // Optionally show an error to the user
                            }
                        }
                    }
                }
                .padding(.horizontal) // Standard horizontal padding for the content
                .padding(.vertical, 20) // Top and bottom padding for the VStack content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Ensure VStack fills its space
                .border(DSColor.border)
                
            }
        }
    }
}

// Helper View for individual menu items
struct MenuItem: View {
    let iconName: String
    let title: String
    var role: ButtonRole? = nil // For styling destructive actions like sign out
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) { // Increased spacing a bit
                Image(systemName: iconName)
                    .font(.system(size: 20)) // Consistent icon size
                    .frame(width: 24, alignment: .center) // Helps align icons if they vary in width
                    .foregroundStyle(role == .destructive ? Color.red : DSColor.accent)
                
                Text(title)
                    .font(.system(size: 17, weight: .medium)) // Clear font for readability
                    .foregroundStyle(role == .destructive ? Color.red : DSColor.textPrimary)
                
                Spacer() // Pushes content to leading, useful if you add a chevron or something later
            }
            .padding(.vertical, 12) // Comfortable tap target height
            .contentShape(Rectangle()) // Makes the entire HStack area tappable
        }
        .buttonStyle(.plain) // Removes default button styling to use our custom HStack look
    }
}

// Helper View for a styled divider
struct MenuDivider: View {
    var body: some View {
        Divider()
            .background(DSColor.textSecondary.opacity(0.3))
            .padding(.vertical, 10) // Spacing around the divider
    }
}

// Example Header View (Customize as needed)
struct MenuHeaderView: View {
    @Environment(Clerk.self) private var clerk // Access user info if available

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // You might fetch the user's image URL from Clerk
            Image(systemName: "person.crop.circle.fill") // Placeholder
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundStyle(DSColor.accent.opacity(0.7))
                .clipShape(Circle())
                .padding(.bottom, 5)
            
            // Display user's name or email from Clerk if available
            Text(clerk.user?.firstName ?? "User Name")
                .font(.title2.bold())
                .foregroundStyle(DSColor.textPrimary)
            
            if let emailAddress = clerk.user?.primaryEmailAddress?.emailAddress {
                Text(emailAddress)
                    .font(.footnote)
                    .foregroundStyle(DSColor.textSecondary)
                    .tint(DSColor.accent) // Make it look like a link if you want
            }
        }
        .padding(.bottom, 10) // Space after the header content
    }
}
