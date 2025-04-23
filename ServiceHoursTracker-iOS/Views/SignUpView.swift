//
//  SignUpView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-22.
//

import SwiftUI
import Clerk
import os.log

struct SignUpView: View {
    // Access the Clerk instance from the environment
    @Environment(Clerk.self) private var clerk
    
    // State for form fields
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var oen = ""
    @State private var schoolID = ""
    
    // State for verification step
    @State private var isVerifying = false
    @State private var code = ""
    
    // State for potential errors
    @State private var errorMessage: String?
    
    // Logger instance
    private var logger: Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SignUpView")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create Your Account")
                .font(.title)
                .fontWeight(.bold)
            
            if isVerifying {
                // --- Verification Code UI ---
                Text("Enter the code sent to \(email)")
                    .font(.subheadline)
                
                TextField("Verification Code", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Verify Email") {
                    Task { await verify(code: code) }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
            } else {
                // --- Initial Sign Up Form UI ---
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                SecureField("Password (8+ characters)", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextField("OEN Number", text: $oen)
                    .keyboardType(.numberPad) // Adjust keyboard type if needed
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextField("School ID", text: $schoolID)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Sign Up") {
                    Task { await signUp() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            
            // Display error messages
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()

    }
}

extension SignUpView {
    
    func signUp() async {
        errorMessage = nil // Clear previous errors
        
        // Basic frontend validation (adjust based on actual requirements)
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty, !oen.isEmpty, !schoolID.isEmpty else {
            errorMessage = "Please fill out all fields."
            return
        }
        
        // Ensure clerk client is available
        guard let client = clerk.client else {
            errorMessage = "Clerk client not initialized."
            logger.error("Clerk client not initialized during signUp.")
            return
        }
        
        // Prepare metadata dictionary to send to Clerk
        // Using unsafeMetadata is often necessary during sign-up for arbitrary data
        let metadataToSet: [String: String] = [
            "oen": oen,
            "schoolId": schoolID
        ]
        
       
        
        logger.info("Preparing sign up with metadata: \(metadataToSet)")
        let updateParams: SignUp.UpdateParams
        
        do {

            
            let signUp = try await SignUp.create(
                    strategy: .standard(
                        emailAddress: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName))
            
            let encoder = JSONEncoder()
            let jsonValue = try JSON(metadataToSet)
            let updateParams = SignUp.UpdateParams(unsafeMetadata: jsonValue)

            try await signUp.update(params: updateParams)
            
//            // Prepare for the email verification step
//            if signUp.verifications.emailAddress.status != .verified {
//                 try await signUp.prepareVerification(strategy: .emailCode)
//                 isVerifying = true // Move to the code entry view state
//                 logger.info("Sign up prepared, awaiting verification code for \(email)")
//            } else {
//                 logger.info("Sign up completed and email already verified for \(email)")
//                 // Handle auto-verified case if necessary
//            }
            try await signUp.prepareVerification(strategy: .emailCode)
            
            isVerifying = true
            
            print("Reached the end")
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            dump(error)
        }
    }
    
//    func verify(code: String) async {
//        errorMessage = nil
//        
//        guard let client = clerk.client, let signUp = client.signUp else {
//            errorMessage = "Sign up process not found."
//            logger.error("Clerk client or sign up process not found during verification.")
//            isVerifying = false // Reset state
//            return
//        }
//        
//        do {
//            // Attempt to verify the email using the code
//            let result = try await signUp.attemptVerification(strategy: .emailCode(code: code))
//            
//            // Check if sign up is complete and set the session
//            if result.status == .complete {
//                 logger.info("Sign up verification successful and complete for \(email)")
//                 // Setting the session makes the user logged in within the SDK
//                 try await clerk.client?.session?.set(session: result.createdSessionId, beforeEmit: nil)
//                 isVerifying = false // Verification done
//                 // Navigation away from signup should happen automatically
//                 // if your root view observes Clerk's auth state.
//            } else {
//                 logger.warning("Sign up verification status: \(result.status)")
//                 errorMessage = "Verification might not be complete. Status: \(result.status)"
//            }
//            
//        } catch {
//            logger.error("Sign up verification failed: \(error.localizedDescription)")
//            errorMessage = error.localizedDescription
//            dump(error)
//        }
//    }
    
    func verify(code: String) async {
        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                isVerifying = false
                return
            }
            
            
            try await signUp.attemptVerification(strategy: .emailCode(code: code))
            let session = Clerk.shared.session
            
            if let token = try await session?.getToken()?.jwt {
                print("token: \(token)")
            }
            
        } catch {
            dump(error)
        }
    }
}
