//
//  SubmissionsView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

import SwiftUI

enum SubmissionType: String, CaseIterable {
    case completed = "Completed"
    case incomplete = "Incomplete"
    
    var fullName: String {
        switch self {
        case .completed: return "Completed Submissions"
        case .incomplete: return "Incomplete Submissions"
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.seal.text.page"
        case .incomplete: return "chart.line.text.clipboard"
        }
    }
}


struct SubmissionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    @State private var selectedSubmissionType: SubmissionType = .completed
    
    var body: some View {
        VStack(spacing: 0) {
            CustomSegmentedPicker(selection: $selectedSubmissionType)
                .padding(DSSpacing.md)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            
            Group {
                switch selectedSubmissionType {
                case .completed:
                    CompleteSubmissonsView(viewModel: viewModel)
                case .incomplete:
                    IncompleteSubmissionsView(viewModel: viewModel)
                }
            }
        }
        //        .onAppear {
        //            Task {
        //                await viewModel.fetchUserSubmissions()
        //            }
        //        }
        .toolbar {
            sharedToolbarItems(currentTab: .submissionsTab, coordinator: nav)
        }
        .background(DSColor.backgroundSecondary)
        
    }
}


struct CustomSegmentedPicker: View {
    @Binding var selection: SubmissionType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SubmissionType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(DSTypography.subheadline)
                        .foregroundStyle(selection == type ? DSColor.accent : DSColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DSSpacing.sm)
                        .background(
                            selection == type ?
                            DSColor.accent.opacity(0.1) :
                            Color.clear
                        )
                }
            }
        }
        .background(.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DSColor.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }
}
