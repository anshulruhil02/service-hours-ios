//
//  SignaturePadView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-10.
//

import SwiftUI

struct SignaturePadView: View {
    let title: String
    @Binding var isSigning: Bool
    @Binding var clearSignature: Bool
    @Binding var signatureImage: UIImage?
    @Binding var signaturePDF: Data?
    @Binding var signaturePNGData: Data?
    var previousSignature: Image?
    
    var displayPreviousSignature: Bool {
        return previousSignature != nil
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .foregroundColor(DSColor.textPrimary)
            
            if displayPreviousSignature {
                previousSignature
                    .frame(height: 150) // Adjusted height
                    .frame(maxWidth: .infinity)
                    .background(DSColor.backgroundSecondary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DSColor.border, lineWidth: 1)
                    )
                
            } else {
                
                ZStack(alignment: isSigning ? .topTrailing : .center) {
                    SignatureViewContainer(
                        clearSignature: $clearSignature,
                        signatureImage: $signatureImage,
                        pdfSignature: $signaturePDF,
                        signaturePNGData: $signaturePNGData
                    )
                    .disabled(!isSigning)
                    .frame(height: 150) // Adjusted height
                    .frame(maxWidth: .infinity)
                    .background(DSColor.backgroundSecondary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSigning ? DSColor.accent : DSColor.border, lineWidth: isSigning ? 3 : 1)
                    )
                    
                    if signatureImage != nil && !isSigning { // Show "Edit" if image exists and not currently signing
                        Button(action: {
                            isSigning = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .foregroundColor(DSColor.accent)
                                .frame(width: 30, height: 30)
                                .background(DSColor.backgroundPrimary.opacity(0.8)) // So it stands out
                                .clipShape(Circle())
                        }
                    } else if isSigning {
                        Button(action: {
                            isSigning = false
                            clearSignature = true // This will trigger the clear in SignatureViewContainer
                            signatureImage = nil // Also clear the image binding here
                            signaturePDF = nil
                            signaturePNGData = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DSColor.statusError)
                                .padding(5) // Padding around the clear button
                                .background(DSColor.backgroundSecondary.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(5) // Padding for the button itself for easier tapping
                    } else { // No image, not signing -> "Sign Here"
                        Button(action: {
                            isSigning = true
                        }) {
                            VStack(alignment: .center, spacing: 4) { // Adjusted spacing
                                Image(systemName: "pencil.and.scribble") // More relevant icon
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(DSColor.textSecondary) // Changed from .black
                                    .frame(width: 30, height: 30) // Adjusted size
                                Text("Sign here")
                                    .font(.caption) // Consider DSFont.caption
                                    .foregroundColor(DSColor.textPlaceholder) // Changed from .gray
                            }
                            .padding() // Add padding to make the tappable area larger
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Make button fill ZStack area
                    }
                }
            }
        }
    }
}
