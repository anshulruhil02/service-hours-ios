//  DSIconButton.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-07.
//

import SwiftUI

// MARK: - Icon Button Size Variants
enum DSIconButtonSize {
    case small
    case medium
    case large
    case extraLarge
    
    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        case .extraLarge: return 64
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        case .extraLarge: return 28
        }
    }
}

// MARK: - Icon Button State
enum DSIconButtonState {
    case normal
    case pressed
    case disabled
    case loading
}

// MARK: - DSIconButton Component
struct DSIconButton: View {
    let icon: Image
    let action: () -> Void
    let accessibilityLabel: String
    
    var style: DSButtonStyle = .primary
    var size: DSIconButtonSize = .medium
    var isLoading: Bool = false
    var isEnabled: Bool = true
    
    @State private var isPressed: Bool = false
    
    init(
        icon: Image,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.iconSize, height: size.iconSize)
                        .foregroundStyle(textColor)
                }
            }
            .frame(width: size.dimension, height: size.dimension)
//            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityLabel)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Computed Properties
    
    private var currentState: DSIconButtonState {
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
        default: return DSRadius.sm // Smaller radius for icon buttons
        }
    }
}

// MARK: - DSIconButton Modifiers
extension DSIconButton {
    func buttonStyle(_ style: DSButtonStyle) -> DSIconButton {
        var button = self
        button.style = style
        return button
    }
    
    func buttonSize(_ size: DSIconButtonSize) -> DSIconButton {
        var button = self
        button.size = size
        return button
    }
    
    func loading(_ isLoading: Bool = true) -> DSIconButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    func enabled(_ isEnabled: Bool = true) -> DSIconButton {
        var button = self
        button.isEnabled = isEnabled
        return button
    }
}

// MARK: - Convenience Initializers
extension DSIconButton {
    // System icon convenience
    init(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.init(
            icon: Image(systemName: systemName),
            accessibilityLabel: accessibilityLabel,
            action: action
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DSSpacing.xl) {
        // Different styles
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Icon Button Styles")
                .font(DSTypography.headline)
            
            HStack(spacing: DSSpacing.md) {
                DSIconButton(systemName: "plus", accessibilityLabel: "Add") {}
                    .buttonStyle(.primary)
                
                DSIconButton(systemName: "pencil", accessibilityLabel: "Edit") {}
                    .buttonStyle(.secondary)
                
                DSIconButton(systemName: "gear", accessibilityLabel: "Settings") {}
                    .buttonStyle(.tertiary)
                
                DSIconButton(systemName: "trash", accessibilityLabel: "Delete") {}
                    .buttonStyle(.destructive)
                
                DSIconButton(systemName: "heart", accessibilityLabel: "Like") {}
                    .buttonStyle(.ghost)
            }
        }
        
        Divider()
        
        // Different sizes
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Icon Button Sizes")
                .font(DSTypography.headline)
            
            HStack(spacing: DSSpacing.md) {
                DSIconButton(systemName: "star", accessibilityLabel: "Star") {}
                    .buttonSize(.small)
                
                DSIconButton(systemName: "star", accessibilityLabel: "Star") {}
                    .buttonSize(.medium)
                
                DSIconButton(systemName: "star", accessibilityLabel: "Star") {}
                    .buttonSize(.large)
                
                DSIconButton(systemName: "star", accessibilityLabel: "Star") {}
                    .buttonSize(.extraLarge)
            }
        }
        
        Divider()
        
        // States
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Icon Button States")
                .font(DSTypography.headline)
            
            HStack(spacing: DSSpacing.md) {
                DSIconButton(systemName: "checkmark", accessibilityLabel: "Complete") {}
                    .buttonStyle(.primary)
                
                DSIconButton(systemName: "arrow.clockwise", accessibilityLabel: "Loading") {}
                    .loading(true)
                
                DSIconButton(systemName: "xmark", accessibilityLabel: "Cancel") {}
                    .enabled(false)
            }
        }
        
        Spacer()
    }
    .padding()
}
