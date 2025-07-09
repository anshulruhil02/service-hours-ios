//  DSLogo.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-07.
//

import SwiftUI

// MARK: - Logo Size Variants
enum DSLogoSize {
    case small
    case medium
    case large
    case extraLarge
    
    var width: CGFloat {
        switch self {
        case .small: return 120
        case .medium: return 80
        case .large: return 120
        case .extraLarge: return 160
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 80
        case .large: return 120
        case .extraLarge: return 160
        }
    }
}

// MARK: - Logo Style Variants
enum DSLogoStyle {
    case full        // Logo with text
    case icon        // Icon only
    case text        // Text only
    case monochrome  // Single color version
}

// MARK: - DSLogo Component
struct DSLogo: View {
    var size: DSLogoSize = .medium
    var style: DSLogoStyle = .full
    var tintColor: Color? = nil
    var logoText: String? = nil
    var logoName: String
    
    init(
        size: DSLogoSize = .medium,
        style: DSLogoStyle = .full,
        tintColor: Color? = nil,
        logoText: String? = nil,
        logoName: String
    ) {
        self.size = size
        self.style = style
        self.tintColor = tintColor
        
        if style == .full && (logoText?.isEmpty ?? true) {
            assertionFailure("DSLogo with .full style requires non-empty logoText")
            self.logoText = "Required Text"
        } else {
            self.logoText = logoText
        }
        self.logoName = logoName
    }
    
    var body: some View {
        Group {
            switch style {
            case .full:
                fullLogoView
            case .icon:
                iconOnlyView
            case .text:
                textOnlyView
            case .monochrome:
                monochromeView
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    // MARK: - Logo Variants
    
    private var fullLogoView: some View {
        VStack(spacing: DSSpacing.sm) {
            logoIcon
            displayText
        }
    }
    
    private var iconOnlyView: some View {
        logoIcon
    }
    
    private var textOnlyView: some View {
        displayText
    }
    
    private var monochromeView: some View {
        VStack(spacing: DSSpacing.sm) {
            logoIcon
            displayText
        }
    }
    
    // MARK: - Logo Components
    
    private var logoIcon: some View {
        Image(logoName)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
    }
    
    private var displayText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(logoText ?? "")
                .font(logoFont)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        case .extraLarge: return 64
        }
    }
    
    private var logoFont: Font {
        switch size {
        case .small: return DSTypography.caption
        case .medium: return DSTypography.bodyMedium
        case .large: return DSTypography.headline
        case .extraLarge: return DSTypography.title
        }
    }
    
    private var logoSubFont: Font {
        switch size {
        case .small: return DSTypography.caption
        case .medium: return DSTypography.caption
        case .large: return DSTypography.subheadline
        case .extraLarge: return DSTypography.body
        }
    }
}

// MARK: - DSLogo Modifiers
extension DSLogo {
    func logoSize(_ size: DSLogoSize) -> DSLogo {
        var logo = self
        logo.size = size
        return logo
    }
    
    func logoStyle(_ style: DSLogoStyle) -> DSLogo {
        var logo = self
        logo.style = style
        return logo
    }
    
    func tinted(_ color: Color?) -> DSLogo {
        var logo = self
        logo.tintColor = color
        return logo
    }
    
    func text(_ text: String) -> DSLogo {
        var logo = self
        logo.logoText = text
        return logo
    }
}
