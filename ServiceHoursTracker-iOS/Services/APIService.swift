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
            decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full)
            
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
    
    func fetchSubmissions() async throws -> [SubmissionResponse] {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
        
        guard let url = URL(string: "\(baseURL)/submissions") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("Making request to \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            logger.info("Received status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Handle errors (401, 403, 500 etc.)
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full)
            
            do {
                let submissions = try decoder.decode([SubmissionResponse].self, from: data)
                logger.info("Successfully fetched \(submissions.count) submissions.")
                return submissions
            } catch {
                logger.error("API Error: URLSession request failed - \(error)")
                throw APIError.requestFailed(error)
            }
        } catch let error as APIError {
            throw error
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
    
    func updateUserProfile(profileData: UpdateUserProfileDto) async throws -> UserProfile {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable}
        
        guard let url = URL(string: "\(baseURL)/users/me") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        
        do {
            request.httpBody = try encoder.encode(profileData)
        } catch {
            logger.error("API error: Failed to encode HTTP Body")
            throw APIError.encodingError(error)
        }
        
        logger.info("Making PATCH request to \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 6. Check Response Status Code
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            logger.info("Received status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else { // Expect 200 OK for successful PATCH
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    logger.warning("API Error: Unauthorized (\(httpResponse.statusCode)) on PATCH to \(url.path). Body: \(responseBody ?? "N/A")")
                    try? await Clerk.shared.signOut()
                    throw APIError.unauthorized
                } else {
                    logger.error("API Error: Server returned status code \(httpResponse.statusCode) on PATCH to \(url.path). Body: \(responseBody ?? "N/A")")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody)
                }
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            // If using CodingKeys for snake_case: decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let updatedProfile = try decoder.decode(UserProfile.self, from: data)
                logger.info("Successfully updated user profile for: \(updatedProfile.email)")
                return updatedProfile
            } catch {
                logger.error("API Error: Failed to decode PATCH response JSON from \(url.path) - \(error)")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("API Error: URLSession PATCH request failed for \(url.path) - \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    func submitHours(submissionData: CreateSubmissionDto) async throws -> SubmissionResponse {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
        
        guard let url = URL(string: "\(baseURL)/submissions") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        
        do {
            request.httpBody = try encoder.encode(submissionData)
        } catch {
            throw APIError.encodingError(error)
        }
        
        logger.info("Making POST request to \(url)")
        
        do {
            let (data, respone) = try await URLSession.shared.data(for: request)
            guard let httpResponse = respone as? HTTPURLResponse else { throw APIError.invalidURL }
            
            guard httpResponse.statusCode == 201 else {
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    logger.warning("API Error: Unauthorized (\(httpResponse.statusCode)) on POST to \(url.path). Body: \(responseBody ?? "N/A")")
                    try? await Clerk.shared.signOut()
                    throw APIError.unauthorized
                } else {
                    logger.error("API Error: Server returned status code \(httpResponse.statusCode) on PATCH to \(url.path). Body: \(responseBody ?? "N/A")")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full)
            
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    logger.debug("Raw JSON response string:\n\(jsonString)")
                } else {
                    logger.error("Could not convert response data to string.")
                }
                let createSubmission = try decoder.decode(SubmissionResponse.self, from: data)
                logger.info("Successfully created submission: \(createSubmission.id)")
                return createSubmission
            } catch {
                logger.error("API Error: Failed to decode POST response JSON from \(url.path) - \(error)")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("API Error: URLSession POST request failed for \(url.path) - \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    func updateSubmission(submissionId: String, existingSubmission: CreateSubmissionDto) async throws -> SubmissionResponse {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
        guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(existingSubmission)
        } catch {
            throw APIError.encodingError(error)
        }
        
        logger.info("Sending a patch request to update submission")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full)
            do {
                let updatedSubmission = try decoder.decode(SubmissionResponse
                    .self, from: data)
                return updatedSubmission
            } catch {
                throw APIError.decodingError(error)
            }
        } catch {
            logger.error("API Error: URLSession PATCH request failed for \(url.path) - \(error)")
            throw APIError.requestFailed(error)
        }
    }
    
    // This fucntion fetches the URL that allows us to store the signature inside AWS s3 bucket
    func getSupervisorSignatureUploadUrl(submissionId: String) async throws -> (uploadUrl: URL, key: String) {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
        guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/supervisor-signature-upload-url") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("Requesting S3 upload URL for submission \(submissionId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            logger.info("Received status code for upload URL request: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(UploadUrlResponse.self, from: data)
                guard let uploadUrl = URL(string: decodedResponse.uploadUrl) else {
                    logger.error("Failed to create URL from received uploadUrl string: \(decodedResponse.uploadUrl)")
                    throw APIError.invalidResponse // Treat invalid URL string as invalid response
                }
                logger.info("Successfully received S3 upload URL and key.")
                return (uploadUrl: uploadUrl, key: decodedResponse.key)
            } catch {
                logger.error("API Error: Failed to decode upload URL response JSON - \(error)")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError { throw error }
        catch { throw APIError.requestFailed(error) }
    }
    
    // This function sends the put request using the uploadUrl and signature key extracted from teh response of teh get request by getSignatureUploadUrl()
    func uploadSupervisorSignatureToS3(uploadUrl: URL, imageData: Data) async throws {
           var request = URLRequest(url: uploadUrl)
           request.httpMethod = "PUT"
           // Set the Content-Type header EXACTLY as specified when generating the URL (likely image/png)
           request.setValue("image/png", forHTTPHeaderField: "Content-Type")
           // Content-Length is often set automatically by URLSession from httpBody size
           // request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")

           logger.info("Uploading signature data (\(imageData.count) bytes) directly to S3...")

           do {
               // Perform the upload using URLSession's upload(for:from:) method
               let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)

               guard let httpResponse = response as? HTTPURLResponse else {
                   logger.error("S3 Upload Error: Invalid response received.")
                   throw APIError.invalidResponse
               }
               
               logger.info("Received S3 upload status code: \(httpResponse.statusCode)")

               // S3 typically returns 200 OK for a successful PUT
               guard (200...299).contains(httpResponse.statusCode) else {
                   // Attempt to read error body from S3 if possible
                   // let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                   // logger.error("S3 Upload Error: Status \(httpResponse.statusCode). Body: \(errorBody)")
                   throw APIError.s3UploadFailed(statusCode: httpResponse.statusCode)
               }
               
               logger.info("Signature successfully uploaded to S3.")

           } catch let error as APIError {
               throw error // Re-throw known API errors
           } catch {
               logger.error("S3 Upload Error: URLSession upload task failed - \(error)")
               throw APIError.requestFailed(error)
           }
       }
    
    func saveSupervisorSignatureReference(submissionId: String, signatureKey: String) async throws -> SubmissionResponse {
            guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
            guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
            guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/supervisor-signature") else { throw APIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let bodyDto = SaveSignatureDto(signatureKey: signatureKey)
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(bodyDto)
            } catch {
                throw APIError.encodingError(error)
            }

            logger.info("Saving signature reference (key: \(signatureKey)) for submission \(submissionId)")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
                logger.info("Received status code for save reference request: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseBody = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                    else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full) // Use custom formatter
                do {
                    let updatedSubmission = try decoder.decode(SubmissionResponse.self, from: data)
                    logger.info("Successfully saved signature reference for submission \(submissionId)")
                    return updatedSubmission
                } catch {
                    logger.error("API Error: Failed to decode save reference response JSON - \(error)")
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError { throw error }
              catch { throw APIError.requestFailed(error) }
        }
    
    
    func getSupervisorSignatureViewUrl(submissionId: String) async throws -> URL? {
            guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
            guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
            // Target the new GET /submissions/:id/signature endpoint
            guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/supervisor-signature") else { throw APIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            logger.info("Requesting signature view URL for submission \(submissionId)")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
                logger.info("Received status code for view URL request: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseBody = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                    // Handle 404 specifically if backend sends it when signatureUrl is null
                    else if httpResponse.statusCode == 404 {
                         logger.info("Signature not found on backend for submission \(submissionId).")
                         return nil // Return nil explicitly if backend indicates not found
                    }
                    else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
                }
                
                let decoder = JSONDecoder()
                do {
                    let decodedResponse = try decoder.decode(ViewUrlResponse.self, from: data)
                    if let urlString = decodedResponse.viewUrl, let viewUrl = URL(string: urlString) {
                         logger.info("Successfully received signature view URL.")
                        return viewUrl // Return the URL object
                    } else {
                         logger.info("Received null or invalid view URL string from backend.")
                        return nil // Return nil if the URL string is null or invalid
                    }
                } catch {
                    logger.error("API Error: Failed to decode view URL response JSON - \(error)")
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError { throw error }
              catch { throw APIError.requestFailed(error) }
        } // End getSignatureViewUrl
    
    // This fucntion fetches the URL that allows us to store the signature inside AWS s3 bucket
    func getPreApprovedSignatureUploadUrl(submissionId: String) async throws -> (uploadUrl: URL, key: String) {
        guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
        guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
        guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/pre-approved-signature-upload-url") else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logger.info("Requesting S3 upload URL for submission \(submissionId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            logger.info("Received status code for upload URL request: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8)
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(UploadUrlResponse.self, from: data)
                guard let uploadUrl = URL(string: decodedResponse.uploadUrl) else {
                    logger.error("Failed to create URL from received uploadUrl string: \(decodedResponse.uploadUrl)")
                    throw APIError.invalidResponse // Treat invalid URL string as invalid response
                }
                logger.info("Successfully received S3 upload URL and key.")
                return (uploadUrl: uploadUrl, key: decodedResponse.key)
            } catch {
                logger.error("API Error: Failed to decode upload URL response JSON - \(error)")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError { throw error }
        catch { throw APIError.requestFailed(error) }
    }
    
    // This function sends the put request using the uploadUrl and signature key extracted from teh response of teh get request by getSignatureUploadUrl()
    func uploadPreApprovedSignatureToS3(uploadUrl: URL, imageData: Data) async throws {
           var request = URLRequest(url: uploadUrl)
           request.httpMethod = "PUT"
           // Set the Content-Type header EXACTLY as specified when generating the URL (likely image/png)
           request.setValue("image/png", forHTTPHeaderField: "Content-Type")
           // Content-Length is often set automatically by URLSession from httpBody size
           // request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")

           logger.info("Uploading signature data (\(imageData.count) bytes) directly to S3...")

           do {
               // Perform the upload using URLSession's upload(for:from:) method
               let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)

               guard let httpResponse = response as? HTTPURLResponse else {
                   logger.error("S3 Upload Error: Invalid response received.")
                   throw APIError.invalidResponse
               }
               
               logger.info("Received S3 upload status code: \(httpResponse.statusCode)")

               // S3 typically returns 200 OK for a successful PUT
               guard (200...299).contains(httpResponse.statusCode) else {
                   // Attempt to read error body from S3 if possible
                   // let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                   // logger.error("S3 Upload Error: Status \(httpResponse.statusCode). Body: \(errorBody)")
                   throw APIError.s3UploadFailed(statusCode: httpResponse.statusCode)
               }
               
               logger.info("Signature successfully uploaded to S3.")

           } catch let error as APIError {
               throw error // Re-throw known API errors
           } catch {
               logger.error("S3 Upload Error: URLSession upload task failed - \(error)")
               throw APIError.requestFailed(error)
           }
       }
    
    func savePreApprovedSignatureReference(submissionId: String, signatureKey: String) async throws -> SubmissionResponse {
            guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
            guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
            guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/pre-approved-signature") else { throw APIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let bodyDto = SaveSignatureDto(signatureKey: signatureKey)
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(bodyDto)
            } catch {
                throw APIError.encodingError(error)
            }

            logger.info("Saving signature reference (key: \(signatureKey)) for submission \(submissionId)")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
                logger.info("Received status code for save reference request: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseBody = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                    else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(APIService.iso8601Full) // Use custom formatter
                do {
                    let updatedSubmission = try decoder.decode(SubmissionResponse.self, from: data)
                    logger.info("Successfully saved signature reference for submission \(submissionId)")
                    return updatedSubmission
                } catch {
                    logger.error("API Error: Failed to decode save reference response JSON - \(error)")
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError { throw error }
              catch { throw APIError.requestFailed(error) }
        }
    
    
    func getPreApprovedSignatureViewUrl(submissionId: String) async throws -> URL? {
            guard let session = await Clerk.shared.session else { throw APIError.noActiveSession }
            guard let token = try? await session.getToken() else { throw APIError.tokenUnavailable }
            // Target the new GET /submissions/:id/signature endpoint
            guard let url = URL(string: "\(baseURL)/submissions/\(submissionId)/pre-approved-signature") else { throw APIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
        request.setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            logger.info("Requesting signature view URL for submission \(submissionId)")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
                logger.info("Received status code for view URL request: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseBody = String(data: data, encoding: .utf8)
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 { throw APIError.unauthorized }
                    // Handle 404 specifically if backend sends it when signatureUrl is null
                    else if httpResponse.statusCode == 404 {
                         logger.info("Signature not found on backend for submission \(submissionId).")
                         return nil // Return nil explicitly if backend indicates not found
                    }
                    else { throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseBody) }
                }
                
                let decoder = JSONDecoder()
                do {
                    let decodedResponse = try decoder.decode(ViewUrlResponse.self, from: data)
                    if let urlString = decodedResponse.viewUrl, let viewUrl = URL(string: urlString) {
                         logger.info("Successfully received signature view URL.")
                        return viewUrl // Return the URL object
                    } else {
                         logger.info("Received null or invalid view URL string from backend.")
                        return nil // Return nil if the URL string is null or invalid
                    }
                } catch {
                    logger.error("API Error: Failed to decode view URL response JSON - \(error)")
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError { throw error }
              catch { throw APIError.requestFailed(error) }
        } // End getSignatureViewUrl

    // Inside APIService class
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

}

// Helper struct for handling empty responses if needed
struct EmptyResponse: Codable {}




