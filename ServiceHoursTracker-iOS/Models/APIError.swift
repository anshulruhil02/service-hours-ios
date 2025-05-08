//
//  APIError.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-08.
//

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case noActiveSession
    case tokenUnavailable
    case s3UploadFailed(statusCode: Int?)
}
