//
//  UserResponse.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-13.
//

import Foundation


struct UserResponse: Codable, Identifiable {
    let id: String
    let authProviderId: String
    let email: String
    let name: String
    let schoolId: String?
    let oen: String?
    let createdAt: Date
    let updatedAt: Date
    let studentSignatureUrl: String?
    let parentSignatureUrl: String?
    
}
