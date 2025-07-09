//
//  SignInView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-22.
//

import SwiftUI
import Clerk

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    var body: some View {
        ZStack {
            DSCard {
                VStack(spacing: DSSpacing.lg) {
                    Text("Welcome Back")
                        .font(DSTypography.largeTitleThin)
                        .foregroundColor(DSColor.textPrimary)
                        .padding(.bottom, DSSpacing.sm)
                    
                    Text("Log in below with your credentials")
                        .font(DSTypography.bodyMedium)
                        .foregroundStyle(DSColor.textSecondary)
                    
                    DSTextField(
                        "Email Address",
                        text: $email,
                        leadingImage: Image(systemName: "person"),
                        keyboardType: .emailAddress)
                    
                    DSSecureField(
                        "Password",
                        text: $password,
                        leadingImage: Image(systemName: "lock"),
                        showValidation: false
                    )
                    
                    // Display error messages
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(DSColor.statusError)
                            .font(DSTypography.caption)
                            .padding(.top, DSSpacing.xs)
                    }
                    
                    DSButton("Sign In") {
                        Task { await submit(email: email, password: password) }
                    }
                    .buttonStyle(.primary)
                    .buttonSize(.large)
                    .fullWidth()
                    .enabled(isFormValid)
                    .loading(isLoading)
                    
                }
            }
        }
        .padding(DSSpacing.lg)
        .background(DSColor.backgroundPrimary)
    }
}

extension SignInView {
    
    func submit(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        
        do {
            try await SignIn.create(
                strategy: .identifier(email, password: password)
            )
            // Success - loading will be handled by navigation/state change
        } catch {
            // Handle error and stop loading
            isLoading = false
            errorMessage = "Sign in failed. Please check your credentials."
            dump(error)
        }
    }
}

// MARK: - Preview
#Preview("Default") {
    SignInView()
}
