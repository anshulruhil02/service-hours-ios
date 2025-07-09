//
//  NavigationCoordinator.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-08.
//

import Foundation
import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: TabIdentifier = .homeTab
    
    @Published var homeNavigationPath = NavigationPath()
    @Published var submissionsNavigationPath = NavigationPath()
    @Published var exportNavigationPath = NavigationPath()
    
    enum Route: Hashable {
        case userProfile
        case recordSubmission
        //        case submissionDetail(id: String)
        
        var hidesTabBar: Bool {
            switch self {
            case .userProfile, .recordSubmission:
                return true
            }
        }
    }
    
    var shouldHideTabBar: Bool {
        return !homeNavigationPath.isEmpty ||
        !submissionsNavigationPath.isEmpty ||
        !exportNavigationPath.isEmpty
    }
    
    func selectTab(_ tab: TabIdentifier) {
        selectedTab = tab
    }
    
    func navigateToRoute(_ route: Route, in tab: TabIdentifier) {
        selectTab(tab)
        
        switch tab {
        case .homeTab:
            homeNavigationPath.append(route)
        case .submissionsTab:
            submissionsNavigationPath.append(route)
        case .exportTab:
            exportNavigationPath.append(route)
        }
    }
    
    func popToRoot(for tab: TabIdentifier) {
        switch tab {
        case .homeTab:
            homeNavigationPath.removeLast(homeNavigationPath.count)
        case .submissionsTab:
            submissionsNavigationPath.removeLast(submissionsNavigationPath.count)
        case .exportTab:
            exportNavigationPath.removeLast(exportNavigationPath.count)
        }
    }
    
    func pop(from tab: TabIdentifier) {
        switch tab {
        case .homeTab:
            if !homeNavigationPath.isEmpty {
                homeNavigationPath.removeLast()
            }
        case .submissionsTab:
            if !submissionsNavigationPath.isEmpty {
                submissionsNavigationPath.removeLast()
            }
        case .exportTab:
            if !exportNavigationPath.isEmpty {
                exportNavigationPath.removeLast()
            }
        }
    }
}
