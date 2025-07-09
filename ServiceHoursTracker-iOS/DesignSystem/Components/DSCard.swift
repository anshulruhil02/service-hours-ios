//
//  DSCard.swift
//  ServiceHoursTracker-iOS
//
//  Created by Your Name on 2025-07-06.
//

import SwiftUI

struct DSCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DSSpacing.lg)
            .background(DSColor.backgroundSecondary)
            .cornerRadius(DSRadius.lg)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DSColor.accent.ignoresSafeArea()
        
        DSCard {
            VStack(spacing: DSSpacing.lg) {
                Text("Welcome Back")
                    .font(DSTypography.title)
                
                TextField("Email", text: .constant(""))
                    .padding(DSSpacing.md)
                    .background(Color.white)
                    .cornerRadius(DSRadius.md)
                
                Button("Sign In") { }
                    .padding(DSSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(DSColor.accent)
                    .foregroundColor(DSColor.textOnAccent)
                    .cornerRadius(DSRadius.md)
            }
        }
        .padding(DSSpacing.xl)
    }
}
