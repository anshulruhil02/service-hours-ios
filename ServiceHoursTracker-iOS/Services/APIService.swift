//
//  APIService.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-23.
//

import Foundation
import Clerk
import os.log

class APIService {
    private let baseURL = "http://localhost:3000" // Adjust as needed
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "APIService") // Optional logger

    // Function to fetch the user profile from /users/me FOR LIVE APP USE
    func fetchUserProfile() async throws -> UserProfile {
        
        // 1. Get the Clerk session
        guard let session = await Clerk.shared.session else {
            throw APIError.noActiveSession
        }
        
        // 2. Get the default session token (SDK handles refresh)
        //    NO template option needed here for the real app flow.
        guard let token = try? await session.getToken() else {
             logger.error("API Error: Could not retrieve default Clerk token.")
             throw APIError.tokenUnavailable
        }
        print("token resource object: \(token)")
        print("extracted token: \(token.jwt)")
        
        // 3. Construct the URL
        guard let url = URL(string: "\(baseURL)/users/me") else {
            logger.error("API Error: Invalid URL.")
            throw APIError.invalidURL
        }
        
        // 4. Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 5. Add the Authorization Header using the default token
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("Making request to \(url)") // Debug log

        // 6. Perform the request using URLSession
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 7. Check the response status code
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("API Error: Invalid response received.")
                throw APIError.invalidResponse
            }
            
            logger.info("Received status code: \(httpResponse.statusCode)") // Debug log

            guard (200...299).contains(httpResponse.statusCode) else {
                // Handle specific errors based on status code
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                     logger.warning("API Error: Unauthorized (401/403).")
                     // Potentially trigger sign-out flow here
                     try? await Clerk.shared.signOut()
                     throw APIError.unauthorized
                } else {
                    logger.error("API Error: Server returned status code \(httpResponse.statusCode)")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: "error")
                }
            }
            
            // 8. Decode the JSON response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let userProfile = try decoder.decode(UserProfile.self, from: data)
                logger.info("Successfully fetched user profile: \(userProfile.email)")
                return userProfile
            } catch {
                logger.error("API Error: Failed to decode JSON response - \(error)")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
             throw error // Re-throw known API errors
        } catch {
            logger.error("API Error: URLSession request failed - \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    func post<T: Encodable, R: Decodable>(path: String, body: T, responseType: R.Type) async throws -> R {
            
            // 1. Get Token
            guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
            guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
            
            // 2. Construct URL
            guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
            
            // 3. Create Request & Add Headers
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set Content-Type for POST
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // 4. Encode Request Body
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                logger.error("API Error: Failed to encode request body - \(error)")
                throw APIError.encodingError(error)
            }
            
            logger.info("Making POST request to \(url)")

            // 5. Perform Request
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // 6. Check Response Status Code
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
                logger.info("Received status code: \(httpResponse.statusCode)")
                
                // Check for non-successful status codes (e.g., 200 OK or 201 Created are typical for POST)
                guard (200...299).contains(httpResponse.statusCode) else {
                     let responseBody = String(data: data, encoding: .utf8)
                     if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                         logger.warning("API Error: Unauthorized (\(httpResponse.statusCode)) on POST to \(path). Body: \(responseBody ?? "N/A")")
                         try? await Clerk.shared.signOut()
                         throw APIError.unauthorized
                     } else {
                         logger.error("API Error: Server returned status code \(httpResponse.statusCode) on POST to \(path). Body: \(responseBody ?? "N/A")")
                         throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody)
                     }
                }
                
                // 7. Decode Response Body
                // Handle cases where there might be no response body (e.g., 204 No Content)
                 if data.isEmpty && (responseType == EmptyResponse.self || httpResponse.statusCode == 204) {
                     // If expecting no content or got 204, return a placeholder if needed
                     // This requires EmptyResponse to be defined or adjust based on expected R type
                     if let empty = EmptyResponse() as? R { return empty }
                     else { throw APIError.decodingError(NSError(domain: "APIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected EmptyResponse but type mismatch"]))}
                 }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    let decodedResponse = try decoder.decode(responseType, from: data)
                    logger.info("Successfully received POST response from \(path)")
                    return decodedResponse
                } catch {
                    logger.error("API Error: Failed to decode POST response JSON from \(path) - \(error)")
                    throw APIError.decodingError(error)
                }
                
            } catch let error as APIError {
                 throw error
            } catch {
                logger.error("API Error: URLSession POST request failed for \(path) - \(error)")
                throw APIError.requestFailed(error)
            }
        }
}

// Helper struct for handling empty responses if needed
struct EmptyResponse: Codable {}

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error) // Added for POST
    case unauthorized // 401/403
    case serverError(statusCode: Int, message: String?) // Added message
    case noActiveSession
    case tokenUnavailable
}
