//
//  HomeViewModel.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var submission: [SubmissionResponse] = []
    @Published var showSheet: Bool = false
}
