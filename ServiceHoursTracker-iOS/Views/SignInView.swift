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

    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Add alignment and spacing
            Text("Sign In")
                .font(.largeTitle) // Make title larger
                .fontWeight(.bold)
                .foregroundColor(DSColor.textPrimary)
                .padding(.bottom, 10) // Add some space below title
            
            Group {
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
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
            
            // Display error messages
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(DSColor.statusError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5) // Add space above error
            }
            
            Button {
                Task { await submit(email: email, password: password) }
            } label: {
                HStack { // Use HStack to center content
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(DSColor.textOnAccent)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(DSColor.accent)
            .foregroundColor(DSColor.textOnAccent)
            .controlSize(.large)
            .cornerRadius(8)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            
            Spacer() // Push content to top
        }
        .padding() // Add padding around the whole VStack
    }
}

extension SignInView {

  func submit(email: String, password: String) async {
    do {
      try await SignIn.create(
        strategy: .identifier(email, password: password)
      )
    } catch {
      dump(error)
    }
  }
}
