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
        ZStack {
            DSColor.backgroundPrimary
                .ignoresSafeArea(edges: .all)
            VStack(alignment: .leading, spacing: 15) {
                Text("Create Your Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(DSColor.textPrimary)
                
                if isVerifying {
                    // --- Verification Code UI ---
                    Text("Enter the code sent to \(email)")
                        .font(.subheadline)
                        .foregroundColor(DSColor.textSecondary)
                    
                    TextField("Verification Code", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(DSColor.backgroundSecondary)
                        .foregroundColor(DSColor.textPrimary)
                        .cornerRadius(8)
                    
                    Button("Verify Email") {
                        Task { await verify(code: code) }
                    }
                    frame(maxWidth: .infinity)
                        .padding()
                        .background(DSColor.accent)
                        .foregroundColor(DSColor.textOnAccent)
                        .cornerRadius(8)
                        .disabled(code.isEmpty) // Example of disabling
                        .opacity(code.isEmpty ? 0.7 : 1.0)
                    
                } else {
                    Group {
                        TextField("First Name", text: $firstName)
                        
                        TextField("Last Name", text: $lastName)
                        
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        
                        SecureField("Password (8+ characters)", text: $password)
                            .textContentType(.password)
                    }
                    .padding()
                    .background(DSColor.backgroundSecondary)
                    .foregroundColor(DSColor.textPrimary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DSColor.border, lineWidth: 1)
                    )
                    
                    Button("Sign Up") {
                        Task { await signUp() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DSColor.accent)
                    .foregroundColor(DSColor.textOnAccent)
                    .cornerRadius(8)
                    .disabled(email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) ? 0.7 : 1.0)
                }
                
                // Display error messages
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(DSColor.statusError)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

extension SignUpView {
    
    func signUp() async {
        errorMessage = nil // Clear previous errors
        
        // Basic frontend validation (adjust based on actual requirements)
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "Please fill out all fields."
            return
        }

        do {
            let params = SignUp.CreateParams(
                firstName: firstName,
                lastName: lastName,
                password: password,
                emailAddress: email
            )
            
            print("updated params: \(params)")
           
            var signUp = try await SignUp.create(params)
            print("Sign up updated. Current unsafeMetadata from SDK object: \(signUp.unsafeMetadata ?? "nil")")
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
            
            let result = try await signUp.attemptVerification(strategy: .emailCode(code: code))
            
            if result.status == .complete {
                logger.info("Sign up verification successful and complete for \(email)")

                try await clerk.setActive(sessionId: result.createdSessionId ?? "")
                            
                logger.info("Clerk session set successfully. RootView will handle next steps.")
            } else {
                errorMessage = "Verification might not be complete. Status: \(result.status)"
            }
        } catch {
            dump(error)
        }
    }
}
