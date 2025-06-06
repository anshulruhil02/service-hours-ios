//
//  CreateSubmissionDto.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-30.
//

import Foundation

struct CreateSubmissionDto: Codable {
    let orgName: String?
    let hours: Double? // Use Double to match Float in Prisma/potential decimals
    let telephone: Double?
    let supervisorName: String?
    let submissionDate: String? // Send as ISO8601 string
    let status: String
    let description: String?
    
}

struct SubmissionResponse: Codable, Identifiable {
    let id: String
    let orgName: String?
    let hours: Double?
    let telephone: Double?
    let supervisorName: String?
    let submissionDate: Date
    let description: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let studentId: String
}

struct SaveSignatureDto: Codable {
    let signatureKey: String
}
