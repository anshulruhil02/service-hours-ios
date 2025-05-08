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
                .padding(.bottom, 10) // Add some space below title
            
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress) // Helps with autofill
                .textInputAutocapitalization(.never)
                .padding() // Add padding inside text field
                .background(Color(.systemGray6)) // Light gray background
                .cornerRadius(8) // Rounded corners
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2))) // Subtle border
            
            SecureField("Password", text: $password)
                .textContentType(.password) // Helps with autofill
                .padding() // Add padding inside text field
                .background(Color(.systemGray6)) // Light gray background
                .cornerRadius(8) // Rounded corners
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2))) // Subtle border
                .padding(.bottom, 10) // Add space before button
            
            // Display error messages
            if let errorMessage {
                Text(errorMessage)
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
                            .tint(.white) // Make spinner white for contrast on button
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent) // Prominent blue button style
            .controlSize(.large) // Make button taller
            .disabled(isLoading || email.isEmpty || password.isEmpty) // Disable if loading or fields empty
            
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
