//
//  DSColor.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-09.
//

import SwiftUI

public enum DSColor {

    // MARK: - Accent Colors
    public static let accent: Color = Color("AppAccent")
    public static let accentColor: Color = Color("AppAccentColor") // Assuming this is distinct from AppAccent

    // MARK: - Background Colors
    public static let backgroundPrimary: Color = Color("AppBackgroundPrimary")
    public static let backgroundSecondary: Color = Color("AppBackgroundSecondary")
    public static let disabledBackground: Color = Color("AppDisabledBackground")

    // MARK: - Border Colors
    public static let border: Color = Color("AppBorder")

    // MARK: - Text Colors
    public static let disabledText: Color = Color("AppDisabledText")
    public static let textOnAccent: Color = Color("AppTextOnAccent")
    public static let textOnPrimary: Color = Color("AppTextOnPrimary")
    public static let textPlaceholder: Color = Color("AppTextPlaceholder")
    public static let textPrimary: Color = Color("AppTextPrimary")
    public static let textSecondary: Color = Color("AppTextSecondary")

    // MARK: - Brand/Primary Colors
    public static let primary: Color = Color("AppPrimary")
    public static let secondary: Color = Color("AppSecondary")

    // MARK: - Status Colors
    public static let statusError: Color = Color("AppStatusError")
    public static let statusInfo: Color = Color("AppStatusInfo")
    public static let statusSuccess: Color = Color("AppStatusSuccess")
    public static let statusWarning: Color = Color("AppStatusWarning")
}
