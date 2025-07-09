//
//  DSButtons.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-05.
//

import SwiftUI

// MARK: - Button Style Variants
enum DSButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost
    case link
}

// MARK: - Button Size Variants
enum DSButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DSSpacing.md
        case .medium: return DSSpacing.lg
        case .large: return DSSpacing.xl
        }
    }
    
    var font: Font {
        switch self {
        case .small: return DSTypography.caption
        case .medium: return DSTypography.bodyMedium
        case .large: return DSTypography.headline
        }
    }
}

// MARK: - Button State
enum DSButtonState {
    case normal
    case pressed
    case disabled
    case loading
}

// MARK: - DSButton Component
struct DSButton: View {
    let title: String
    let action: () -> Void
    
    var style: DSButtonStyle = .primary
    var size: DSButtonSize = .medium
    var leadingIcon: Image? = nil
    var trailingIcon: Image? = nil
    var isFullWidth: Bool = false
    var isLoading: Bool = false
    var isEnabled: Bool = true
    
    @State private var isPressed: Bool = false
    
    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else if let leadingIcon {
                    leadingIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(textColor)
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                }
                
                if !isLoading, let trailingIcon {
                    trailingIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var currentState: DSButtonState {
        if !isEnabled || isLoading {
            return isLoading ? .loading : .disabled
        } else if isPressed {
            return .pressed
        } else {
            return .normal
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            switch currentState {
            case .normal: return DSColor.accent
            case .pressed: return DSColor.accent.opacity(0.8)
            case .disabled: return DSColor.disabledBackground
            case .loading: return DSColor.accent.opacity(0.8)
            }
        case .secondary:
            switch currentState {
            case .normal: return DSColor.secondary
            case .pressed: return DSColor.secondary.opacity(0.8)
            case .disabled: return DSColor.disabledBackground
            case .loading: return DSColor.secondary.opacity(0.8)
            }
        case .tertiary:
            switch currentState {
            case .normal: return DSColor.backgroundSecondary
            case .pressed: return DSColor.backgroundSecondary.opacity(0.8)
            case .disabled: return DSColor.disabledBackground
            case .loading: return DSColor.backgroundSecondary.opacity(0.8)
            }
        case .destructive:
            switch currentState {
            case .normal: return DSColor.statusError
            case .pressed: return DSColor.statusError.opacity(0.8)
            case .disabled: return DSColor.disabledBackground
            case .loading: return DSColor.statusError.opacity(0.8)
            }
        case .ghost:
            switch currentState {
            case .normal: return Color.clear
            case .pressed: return DSColor.backgroundSecondary.opacity(0.5)
            case .disabled: return Color.clear
            case .loading: return DSColor.backgroundSecondary.opacity(0.3)
            }
        case .link:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return currentState == .disabled ? DSColor.disabledText : DSColor.textOnPrimary
        case .tertiary:
            return currentState == .disabled ? DSColor.disabledText : DSColor.textPrimary
        case .ghost:
            return currentState == .disabled ? DSColor.disabledText : DSColor.textPrimary
        case .link:
            return currentState == .disabled ? DSColor.disabledText : DSColor.accent
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return Color.clear
        case .tertiary:
            return currentState == .disabled ? DSColor.disabledBackground : DSColor.border
        case .ghost:
            return currentState == .disabled ? DSColor.disabledBackground : DSColor.border.opacity(0.3)
        case .link:
            return Color.clear
        }
    }
    
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .secondary, .destructive, .link:
            return 0
        case .tertiary, .ghost:
            return 1
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .link: return 0
        default: return DSRadius.md
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 20
        }
    }
}

// MARK: - DSButton Modifiers
extension DSButton {
    func buttonStyle(_ style: DSButtonStyle) -> DSButton {
        var button = self
        button.style = style
        return button
    }
    
    func buttonSize(_ size: DSButtonSize) -> DSButton {
        var button = self
        button.size = size
        return button
    }
    
    func leadingIcon(_ icon: Image?) -> DSButton {
        var button = self
        button.leadingIcon = icon
        return button
    }
    
    func trailingIcon(_ icon: Image?) -> DSButton {
        var button = self
        button.trailingIcon = icon
        return button
    }
    
    func fullWidth(_ isFullWidth: Bool = true) -> DSButton {
        var button = self
        button.isFullWidth = isFullWidth
        return button
    }
    
    func loading(_ isLoading: Bool = true) -> DSButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    func enabled(_ isEnabled: Bool = true) -> DSButton {
        var button = self
        button.isEnabled = isEnabled
        return button
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DSSpacing.lg) {
        // Primary buttons
        DSButton("Primary Button") {}
            .buttonStyle(.primary)
        
        DSButton("Secondary Button") {}
            .buttonStyle(.secondary)
        
        DSButton("Tertiary Button") {}
            .buttonStyle(.tertiary)
        
        DSButton("Destructive Button") {}
            .buttonStyle(.destructive)
        
        DSButton("Ghost Button") {}
            .buttonStyle(.ghost)
        
        DSButton("Link Button") {}
            .buttonStyle(.link)
        
        // Size variants
        HStack {
            DSButton("Small") {}
                .buttonSize(.small)
            
            DSButton("Medium") {}
                .buttonSize(.medium)
            
            DSButton("Large") {}
                .buttonSize(.large)
        }
        
        // With icons
        DSButton("With Leading Icon") {}
            .leadingIcon(Image(systemName: "plus"))
        
        DSButton("With Trailing Icon") {}
            .trailingIcon(Image(systemName: "arrow.right"))
        
        // Full width
        DSButton("Full Width Button") {}
            .fullWidth()
        
        // Loading state
        DSButton("Loading Button") {}
            .loading(true)
        
        // Disabled state
        DSButton("Disabled Button") {}
            .enabled(false)
    }
    .padding()
}
