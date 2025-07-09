//
//  ProgressBar.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-08.
//


import SwiftUI

struct ServiceHoursProgressView: View {
    let hoursApproved: Double
    let hoursSubmitted: Double
    let maxHours: Double = 40
    
    private var approvedPercentage: Double {
        min(hoursApproved / maxHours, 1.0)
    }
    
    private var submittedPercentage: Double {
        min(hoursSubmitted / maxHours, 1.0)
    }
    
    private var displayPercentage: Int {
        Int(approvedPercentage * 100)
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.xxl * 2) {
            // Progress Circle
            ZStack {
                // Background circle (total hours)
                Circle()
                    .stroke(
                        DSColor.border.opacity(0.3),
                        style: StrokeStyle(lineWidth: DSSpacing.xl, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                
                // Approved hours arc (starts from 0)
                Circle()
                    .trim(from: 0, to: approvedPercentage)
                    .stroke(
                        DSColor.statusSuccess,
                        style: StrokeStyle(lineWidth: DSSpacing.xl, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: approvedPercentage)
                
                // Pending hours arc (from approved end to submitted end)
                Circle()
                    .trim(from: approvedPercentage, to: submittedPercentage + approvedPercentage)
                    .stroke(
                        DSColor.statusWarning,
                        style: StrokeStyle(lineWidth: DSSpacing.xl, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: submittedPercentage)
                
                
                // Center text
                VStack(spacing: DSSpacing.sm) {
                    Text("\(displayPercentage)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(DSColor.textPrimary)
                    
                    Text("Approved")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(DSColor.textSecondary)
                }
            }
            
            // Legend
            VStack(spacing: DSSpacing.md) {
                HStack(spacing: DSSpacing.md) {
                    Circle()
                        .fill(DSColor.border.opacity(0.3))
                        .frame(width: DSSpacing.lg, height: DSSpacing.lg)
                    
                    Text("Total Goal (\(Int(maxHours)))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DSColor.textSecondary)
                    
                    Spacer()
                }
                
                HStack(spacing: DSSpacing.md) {
                    Circle()
                        .fill(DSColor.statusWarning)
                        .frame(width: DSSpacing.lg, height: DSSpacing.lg)
                    
                    Text("Submitted (\(Int(hoursSubmitted)))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DSColor.textSecondary)
                    
                    Spacer()
                }
                
                HStack(spacing: DSSpacing.md) {
                    Circle()
                        .fill(DSColor.statusSuccess)
                        .frame(width: DSSpacing.lg, height: DSSpacing.lg)
                    
                    Text("Approved (\(Int(hoursApproved)))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DSColor.textSecondary)
                    
                    Spacer()
                }
            }
        }
        .padding(DSSpacing.lg)
    }
}
