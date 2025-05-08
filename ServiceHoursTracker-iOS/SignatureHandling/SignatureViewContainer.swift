//
//  SignatureViewContainer.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-08.
//

import SwiftUI

struct SignatureViewContainer: UIViewRepresentable {
    @Binding var clearSignature: Bool
    @Binding var signatureImage: UIImage?
    @Binding var pdfSignature: Data?
    @Binding var signaturePNGData: Data?
    
    @State private var updateDataToggle: Bool = false
    
    func makeUIView(context: Context) -> ADrawSignatureView {
        let ASignatureView = ADrawSignatureView(backgroundColor: UIColor(Color.white))
        ASignatureView.delegate = context.coordinator
        ASignatureView.strokeColor = UIColor(.green)
        return ASignatureView
    }
    
    func updateUIView(_ uiView: ADrawSignatureView, context: Context) {
        if clearSignature {
            uiView.clear()
            DispatchQueue.main.async {
                clearSignature.toggle()
                signatureImage = nil
                pdfSignature = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(signatureContainer: self)
    }
    
    func updateSignature() {
        updateDataToggle.toggle()
    }
}

extension SignatureViewContainer {
    class Coordinator: ASignatureDelegate {
        var signatureContainer: SignatureViewContainer
        
        init(signatureContainer: SignatureViewContainer) {
            self.signatureContainer = signatureContainer
        }
        
        func didStart() {}
        
        // Inside didFinish method
        func didFinish(_ view: ADrawSignatureView) {
            let capturedImage = view.getSignature() // Get image first

            guard let uiImage = capturedImage else {
                // If getSignature() returned nil, log that specifically
                print("Error: view.getSignature() returned nil.")
                signatureContainer.signatureImage = nil
                signatureContainer.signaturePNGData = nil
                return // Stop here if no image was captured
            }

            // If we get here, uiImage is NOT nil
            signatureContainer.signatureImage = uiImage // Assign the valid image
            print("Signature UIImage obtained. Size: \(uiImage.size)")

            // Now try converting to PNG
            if let pngData = uiImage.pngData(), pngData.count > 0 {
                print("Generated PNG Data count: \(pngData.count) bytes")
                signatureContainer.signaturePNGData = pngData
            } else {
                // Handle the case where pngData() fails or returns empty data
                print("Error: pngData() failed or returned empty data.")
                signatureContainer.signaturePNGData = nil
            }
        }
    }
}

extension UIView {
    
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
}

