//
//  SignUpOrSignInView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-22.
//

import SwiftUI

struct SignUpOrSignInView: View {
  @State private var isSignUp = true

  var body: some View {
    ScrollView {
      if isSignUp {
        SignUpView()
      } else {
        SignInView()
      }

      Button {
        isSignUp.toggle()
      } label: {
        if isSignUp {
          Text("Already have an account? Sign in")
        } else {
          Text("Don't have an account? Sign up")
        }
      }
      .padding()
    }
  }
}
