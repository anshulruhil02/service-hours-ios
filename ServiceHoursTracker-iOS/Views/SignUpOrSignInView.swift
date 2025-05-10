//
//  SignUpOrSignInView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-22.
//

import SwiftUI
import Clerk

struct SignUpOrSignInView: View {
    @State private var isSignUp = true
    @Environment(Clerk.self) private var clerk
    
    var body: some View {
        ZStack {
            DSColor.backgroundPrimary
                .ignoresSafeArea(edges: .all)
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
                .foregroundColor(DSColor.accent) 
                .padding(.vertical)
            }
        }
    }
}
