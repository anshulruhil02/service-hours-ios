//
//  DSProgressScreen.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-09.
//

import SwiftUI

struct DSProgressScreen: View {
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            
            Text("Serve")
                .font(DSTypography.largeTitleThin)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DSColor.accent))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.backgroundPrimary)
    }
}

#Preview {
    DSProgressScreen()
}
