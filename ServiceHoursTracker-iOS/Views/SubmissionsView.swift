//
//  SubmissionsView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI

struct SubmissionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isMenuOpen: Bool
    @State private var selectedTab: TabIdentifier = .completeSubmissions
    
    var body: some View {
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
        .navigationTitle("My Hours")
    }
}

enum TabIdentifier {
    case completeSubmissions
    case incompleteSubmissions
}
