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
            try await signUp.prepareVerification(strategy: .emailCode)
            
            isVerifying = true
            
            print("Reached the end")
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            dump(error)
        }
    }
    
    func verify(code: String) async {
        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                isVerifying = false
                return
            }
            
            try await signUp.attemptVerification(strategy: .emailCode(code: code))
            let apiService = APIService() // Create instance (or get from environment/DI later)
            do {
                let userProfile = try await apiService.fetchUserProfile()
                // SUCCESS! Backend verified token and found/created user in DB.
                logger.info("Successfully fetched profile from backend for user: \(userProfile.email)")
                // TODO: Store userProfile in your app's state management
                //       (e.g., update an @State variable, call a ViewModel function)
                //       This data (role, schoolId, etc.) is now available.
            } catch {
                // Handle errors specifically from fetchUserProfile
                logger.error("Failed to fetch user profile from backend: \(error.localizedDescription)")
                errorMessage = "Login succeeded, but failed to sync profile. Please try again later."
                dump(error) // Log detailed APIError
            }
        } catch {
            dump(error)
        }
    }
}
