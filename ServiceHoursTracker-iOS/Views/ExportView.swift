//
//  ExportView.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-12.
//

// Views/ExportView.swift

import SwiftUI
import os.log

struct ExportView: View {
    @ObservedObject var viewModel: HomeViewModel
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ExportView")

    var body: some View {
        VStack(spacing: 20) {
            // ... (Your existing UI: Image, Texts, Button) ...
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(DSColor.accent)
                .padding(.bottom, 10)
            
            Text("Export Your Submissions")
                .font(.title)
                .foregroundStyle(DSColor.textPrimary)
            
            Text("Tap the button below to generate a PDF report...")
                .font(.body)
                .foregroundStyle(DSColor.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal)

            Button {
                Task {
                    logger.info("Generate Report button tapped.")
                    await viewModel.generateAndPreparePdfReport()
                }
            } label: { /* ... Button Label with Loading State ... */
                HStack {
                    Spacer()
                    if viewModel.isGeneratingReport { ProgressView().tint(.white) }
                    else { Label("Generate & Share PDF Report", systemImage: "square.and.arrow.up.fill").fontWeight(.semibold) }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent).tint(DSColor.primary).controlSize(.large)
            .disabled(viewModel.isGeneratingReport).padding(.top)

            Spacer()
        }
        .padding()
        .navigationTitle("Export Report")
        .navigationBarTitleDisplayMode(.inline)
        // This sheet modifier will present when 'showingShareSheet' becomes true
        .sheet(isPresented: $viewModel.showingShareSheet, onDismiss: {
            // Clean up the temporary file when the sheet is dismissed
            if let url = viewModel.pdfReportFileUrl {
                do {
                    try FileManager.default.removeItem(at: url)
                    logger.info("Removed temporary PDF file: \(url.path)")
                } catch {
                    logger.error("Error removing temporary PDF file: \(error.localizedDescription)")
                }
            }
            viewModel.pdfReportFileUrl = nil // Clear URL
            viewModel.reportError = nil
            logger.info("Share sheet dismissed.")
        }) {
            // This content is shown inside the presented sheet.
            // The ShareLink, when its item is valid, will trigger the system share UI.
            if let pdfURL = viewModel.pdfReportFileUrl { // Use the file URL
                ShareLink(
                    item: pdfURL, // <-- Pass the URL of the saved PDF file
                    preview: SharePreview(
                        "Community Hours Report.pdf", // Suggested filename
                        image: Image(systemName: "doc.richtext.fill")
                    )
                ) {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                }
                // You might want a more explicit UI inside the sheet
                // For example:
                // VStack {
                //     Text("Your PDF report is ready.").padding()
                //     ShareLink(item: pdfURL, /*...*/) { Text("Tap to Share") }
                //         .buttonStyle(.borderedProminent)
                //     Button("Done") { viewModel.showingShareSheet = false }.padding()
                // }
            } else {
                VStack {
                    Text("Preparing report for sharing...")
                    ProgressView()
                }
            }
        }
        // ... (alert for reportError) ...
    }
}
