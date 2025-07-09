
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
    
    // State for loading states
    @State private var isSigningUp = false
    @State private var isVerifyingCode = false
    
    // State for potential errors
    @State private var errorMessage: String?
    
    // Logger instance
    private var logger: Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SignUpView")
    }
    
    // Computed properties for form validation
    private var isFormValid: Bool {
        !email.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        DSPasswordValidator.isValid(password)
    }
    
    private var isCodeValid: Bool {
        !code.isEmpty && code.count >= 4 // Assuming verification codes are at least 4 digits
    }
    
    var body: some View {
        ZStack {
            DSColor.backgroundPrimary
                .ignoresSafeArea(edges: .all)
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                
                if isVerifying {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                            Text("Enter the code sent to \(email)")
                                .font(DSTypography.subheadline)
                                .foregroundColor(DSColor.textSecondary)
                            
                            DSTextField(
                                "Verification Code",
                                text: $code,
                                leadingImage: Image(systemName: "number"),
                                keyboardType: .numberPad,
                                textContentType: .oneTimeCode
                            )
                            
                            DSButton("Verify Email") {
                                Task { await verify(code: code) }
                            }
                            .buttonStyle(.primary)
                            .buttonSize(.large)
                            .fullWidth()
                            .enabled(isCodeValid)
                            .loading(isVerifyingCode)
                        }
                    }
                    
                } else {
                    DSCard {
                        VStack(spacing: DSSpacing.lg) {
                        Text("Create Account")
                            .font(DSTypography.largeTitleThin)
                            .foregroundColor(DSColor.textPrimary)
                            .padding(.bottom, DSSpacing.sm)
                        
                        Text("Sign Up below with your credentials")
                            .font(DSTypography.bodyMedium)
                            .foregroundStyle(DSColor.textSecondary)
                        
                        
                            DSTextField(
                                "First Name",
                                text: $firstName,
                                leadingImage: Image(systemName: "person"),
                                textContentType: .givenName
                            )
                            
                            DSTextField(
                                "Last Name",
                                text: $lastName,
                                leadingImage: Image(systemName: "person"),
                                textContentType: .familyName
                            )
                            
                            DSTextField(
                                "Email Address",
                                text: $email,
                                leadingImage: Image(systemName: "envelope"),
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )
                            
                            DSSecureField(
                                "Password",
                                text: $password,
                                leadingImage: Image(systemName: "lock"),
                                showValidation: true
                            )
                            
                            DSButton("Create Account") {
                                Task { await signUp() }
                            }
                            .buttonStyle(.primary)
                            .buttonSize(.large)
                            .fullWidth()
                            .enabled(isFormValid)
                            .loading(isSigningUp)
                        }
                    }
                }
                
                // Display error messages
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(DSColor.statusError)
                        .font(DSTypography.caption)
                }
            }
            .padding(DSSpacing.lg)
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

//
//// MARK: - Preview
//struct SignUpViewPreview: View {
//    @State private var email = ""
//    @State private var password = ""
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var isVerifying = false
//    @State private var code = ""
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        ZStack {
//            DSColor.backgroundPrimary
//                .ignoresSafeArea(edges: .all)
//            VStack(alignment: .leading, spacing: DSSpacing.lg) {
//                Text("Create Your Account")
//                    .font(DSTypography.title)
//                    .foregroundStyle(DSColor.textPrimary)
//                
//                if isVerifying {
//                    // --- Verification Code UI ---
//                    Text("Enter the code sent to \(email)")
//                        .font(DSTypography.subheadline)
//                        .foregroundColor(DSColor.textSecondary)
//                    
//                    TextField("Verification Code", text: $code)
//                        .keyboardType(.numberPad)
//                        .textContentType(.oneTimeCode)
//                        .padding(DSSpacing.lg)
//                        .background(DSColor.backgroundSecondary)
//                        .foregroundColor(DSColor.textPrimary)
//                        .cornerRadius(DSRadius.md)
//                    
//                    Button("Verify Email") {
//                        // Preview action
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(DSSpacing.lg)
//                    .background(DSColor.accent)
//                    .foregroundColor(DSColor.textOnAccent)
//                    .cornerRadius(DSRadius.md)
//                    .disabled(code.isEmpty)
//                    .opacity(code.isEmpty ? 0.7 : 1.0)
//                    
//                } else {
//                    DSCard {
//                        VStack(spacing: DSSpacing.lg) {
//                            TextField("First Name", text: $firstName)
//                                .padding(DSSpacing.md)
//                                .background(Color.white)
//                                .cornerRadius(DSRadius.md)
//                            
//                            TextField("Last Name", text: $lastName)
//                                .padding(DSSpacing.md)
//                                .background(Color.white)
//                                .cornerRadius(DSRadius.md)
//                            
//                            TextField("Email Address", text: $email)
//                                .keyboardType(.emailAddress)
//                                .textContentType(.emailAddress)
//                                .textInputAutocapitalization(.never)
//                                .padding(DSSpacing.md)
//                                .background(Color.white)
//                                .cornerRadius(DSRadius.md)
//                            
//                            SecureField("Password (8+ characters)", text: $password)
//                                .textContentType(.password)
//                                .padding(DSSpacing.md)
//                                .background(Color.white)
//                                .cornerRadius(DSRadius.md)
//                            
//                            Button("Sign Up") {
//                                // Preview action
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(DSSpacing.lg)
//                            .background(DSColor.accent)
//                            .foregroundColor(DSColor.textOnAccent)
//                            .cornerRadius(DSRadius.md)
//                            .disabled(email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty)
//                            .opacity((email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) ? 0.7 : 1.0)
//                        }
//                    }
//                }
//                
//                // Display error messages
//                if let errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(DSColor.statusError)
//                        .font(DSTypography.caption)
//                }
//                
//                Spacer()
//            }
//            .padding(DSSpacing.lg)
//        }
//    }
//}
//
//#Preview("Sign Up Form") {
//    SignUpViewPreview()
//}
//
//#Preview("Verification State") {
//    SignUpViewPreview()
//        .onAppear {
//            // In a real preview, you'd set isVerifying = true
//            // but this shows the structure
//        }
//}
