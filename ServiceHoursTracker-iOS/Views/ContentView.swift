//
//  ContentView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-04-21.
//

import SwiftUI
import Clerk

struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    
    var body: some View {
        VStack(spacing: 20) {
            if let user = clerk.user {
                Text("Welcome!")
                    .font(.title)
                if let name = user.firstName {
                    Text("User: \(name)")
                }
                Text("User ID: \(user.id)") // Clerk User ID
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // --- Button to Get Test Token ---
                Button("Get Test Token for Postman") {
                    Task {
                        await getAndPrintTestToken()
                    }
                }
                .buttonStyle(.bordered)
                Button("Sign Out") {
                    Task { try? await clerk.signOut() }
                }
            } else {
                SignUpOrSignInView()
            }
        }
    }
    
    func getAndPrintTestToken() async {
        guard let session = clerk.session else {
            print("Error with session fetch... :(")
            return
        }
        
        let tokenOptions = Session.GetTokenOptions(template: "testing2")
        
        do {
            let catchToken = try  await session.getToken(tokenOptions)
            print("Token: \(catchToken)")
        } catch {
            print("error trying to fetch token: \(error)")
        }
    }

}
