//
//  SubmissionsView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI

struct TabSelection: View {
    @StateObject var viewModel = HomeViewModel()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    init() {
        // Set tab bar appearance once during initialization
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DSColor.backgroundPrimary)
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DSColor.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(DSColor.accent)
        ]
        
        // Unselected state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(DSColor.backgroundPrimary)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor.white
    }
    
    var body: some View {
        TabView(selection: Binding(
            get: { navigationCoordinator.selectedTab },
            set: { newTab in
                navigationCoordinator.selectTab(newTab)
            }
        )) {
            
            // Home Tab
            NavigationStack(path: $navigationCoordinator.homeNavigationPath) {
                HomeView(viewModel: viewModel)
                    .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                        destinationView(for: route)
                            .toolbar(.hidden, for: .tabBar)
                    }
            }
            .tabItem {
                Label(TabIdentifier.homeTab.title, systemImage: TabIdentifier.homeTab.systemImage)
            }
            .tag(TabIdentifier.homeTab)
            
            
            // Submissions Tab
            NavigationStack(path: $navigationCoordinator.submissionsNavigationPath) {
                SubmissionsView(viewModel: viewModel)
                    .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                        destinationView(for: route)
                            .toolbar(.hidden, for: .tabBar)
                    }
            }
            .tabItem {
                Label(TabIdentifier.submissionsTab.title, systemImage: TabIdentifier.submissionsTab.systemImage)
            }
            .tag(TabIdentifier.submissionsTab)
            
            // Export Tab
            NavigationStack(path: $navigationCoordinator.exportNavigationPath) {
                ExportView(viewModel: viewModel)
                    .navigationDestination(for: NavigationCoordinator.Route.self) { route in
                        destinationView(for: route)
                            .toolbar(.hidden, for: .tabBar)
                    }
            }
            .tabItem {
                Label(TabIdentifier.exportTab.title, systemImage: TabIdentifier.exportTab.systemImage)
            }
            .tag(TabIdentifier.exportTab)
        }
        .tint(DSColor.accent)
        .environmentObject(navigationCoordinator)
        .onAppear {
            Task {
                await viewModel.fetchUserSubmissions()
            }
        }
    }
    
    // MARK: - Destination View Builder
    @ViewBuilder
    private func destinationView(for route: NavigationCoordinator.Route) -> some View {
        switch route {
        case .userProfile:
            UserInfoView(viewModel: viewModel)
        case .recordSubmission:
            SubmissionFormView()
                .environmentObject(viewModel)
            //        case .submissionDetail(let id):
            //            SubmissionDetailView()
            //        case .settings:
            //            SettingsView()
        }
    }
    
    
}

enum TabIdentifier: String, CaseIterable {
    case homeTab = "home"
    case submissionsTab = "submissions"
    case exportTab = "export"
    
    var title: String {
        switch self {
        case .homeTab: return "Home"
        case .submissionsTab: return "Submissions"
        case .exportTab: return "Export PDF"
        }
    }
    
    var systemImage: String {
        switch self {
        case .homeTab: return "house"
        case .submissionsTab: return "chart.line.text.clipboard"
        case .exportTab: return "square.and.arrow.down"
        }
    }
}
