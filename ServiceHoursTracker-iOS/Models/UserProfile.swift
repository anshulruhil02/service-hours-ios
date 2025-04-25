//
//  UserProfile.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-23.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let schoolId: String?
    let oen: String?
}
