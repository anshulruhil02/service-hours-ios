//  DSTextField.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-07-06.
//

import SwiftUI

// MARK: - Password Validation
enum DSPasswordStrength: CaseIterable {
    case weak, fair, good, strong
    
    var color: Color {
        switch self {
        case .weak: return DSColor.statusError
        case .fair: return DSColor.statusWarning
        case .good: return Color.orange
        case .strong: return DSColor.statusSuccess
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
}

struct DSPasswordRule {
    let description: String
    let isValid: (String) -> Bool
}

class DSPasswordValidator: ObservableObject {
    static let rules: [DSPasswordRule] = [
        DSPasswordRule(description: "At least 8 characters") { $0.count >= 8 },
        DSPasswordRule(description: "Contains uppercase letter") { $0.rangeOfCharacter(from: .uppercaseLetters) != nil },
        DSPasswordRule(description: "Contains lowercase letter") { $0.rangeOfCharacter(from: .lowercaseLetters) != nil },
        DSPasswordRule(description: "Contains number") { $0.rangeOfCharacter(from: .decimalDigits) != nil },
        DSPasswordRule(description: "Contains special character") { $0.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil }
    ]
    
    static func strength(for password: String) -> DSPasswordStrength {
        let validRules = rules.filter { $0.isValid(password) }.count
        
        switch validRules {
        case 0...1: return .weak
        case 2...3: return .fair
        case 4: return .good
        case 5: return .strong
        default: return .weak
        }
    }
    
    static func isValid(_ password: String) -> Bool {
        return rules.allSatisfy { $0.isValid(password) }
    }
    
    static func failedRules(for password: String) -> [DSPasswordRule] {
        return rules.filter { !$0.isValid(password) }
    }
}

struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    let leadingImage: Image?
    let trailingImage: Image?
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    
    @State private var isEditing: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        leadingImage: Image? = nil,
        trailingImage: Image? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingImage = leadingImage
        self.trailingImage = trailingImage
        self.keyboardType = keyboardType
        self.textContentType = textContentType
    }
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            if let leadingImage {
                leadingImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(iconColor)
            }
            
            TextField(placeholder, text: $text) { editing in
                isEditing = editing
            }
            .foregroundColor(textColor)
            .tint(DSColor.accent)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            
            if let trailingImage {
                trailingImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(iconColor)
            }
        }
        .padding(DSSpacing.lg)
        .background(backgroundColor)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Computed Colors
    
    private var backgroundColor: Color {
        isEnabled ? Color.white : DSColor.disabledBackground
    }
    
    private var borderColor: Color {
        if isEditing {
            return DSColor.accent
        } else {
            return DSColor.border.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        isEnabled ? DSColor.textPrimary : DSColor.disabledText
    }
    
    private var iconColor: Color {
        isEnabled ? DSColor.textSecondary : DSColor.disabledText
    }
}

struct DSSecureField: View {
    let placeholder: String
    @Binding var text: String
    let leadingImage: Image?
    let trailingImage: Image?
    let showValidation: Bool
    
    @State private var isEditing: Bool = false
    @State private var showPassword: Bool = false
    @Environment(\.isEnabled) private var isEnabled
    
    private var passwordStrength: DSPasswordStrength {
        DSPasswordValidator.strength(for: text)
    }
    
    private var isPasswordValid: Bool {
        DSPasswordValidator.isValid(text)
    }
    
    private var failedRules: [DSPasswordRule] {
        DSPasswordValidator.failedRules(for: text)
    }
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        leadingImage: Image? = nil,
        trailingImage: Image? = nil,
        showValidation: Bool = true
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingImage = leadingImage
        self.trailingImage = trailingImage
        self.showValidation = showValidation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack(spacing: DSSpacing.md) {
                if let leadingImage {
                    leadingImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(iconColor)
                }
                
                if showPassword {
                    TextField(placeholder, text: $text) { editing in
                        isEditing = editing
                    }
                    .foregroundColor(textColor)
                    .tint(DSColor.accent)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                } else {
                    SecureField(placeholder, text: $text, onCommit: {
                        isEditing = false
                    })
                    .foregroundColor(textColor)
                    .tint(DSColor.accent)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onTapGesture {
                        isEditing = true
                    }
                    .onChange(of: text) { _ in
                        isEditing = true
                    }
                }
                
                // Show trailing image if provided, otherwise show password toggle
                if let trailingImage {
                    trailingImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(iconColor)
                } else {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(iconColor)
                    }
                }
            }
            .padding(DSSpacing.lg)
            .background(backgroundColor)
            .cornerRadius(DSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .stroke(validationBorderColor, lineWidth: 1)
            )
            
            // Password validation UI
            if showValidation && !text.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    // Password strength indicator
                    HStack {
                        Text("Password strength:")
                            .font(DSTypography.caption)
                            .foregroundColor(DSColor.textSecondary)
                        
                        Text(passwordStrength.text)
                            .font(DSTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(passwordStrength.color)
                        
                        Spacer()
                        
                        // Visual strength indicator
                        HStack(spacing: 2) {
                            ForEach(0..<4) { index in
                                Rectangle()
                                    .frame(width: 20, height: 4)
                                    .foregroundColor(index < strengthLevel ? passwordStrength.color : DSColor.border)
                                    .cornerRadius(2)
                            }
                        }
                    }
                    
                    // Failed rules
                    if !failedRules.isEmpty {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            ForEach(failedRules.indices, id: \.self) { index in
                                HStack(spacing: DSSpacing.xs) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(DSColor.statusError)
                                        .font(.caption)
                                    
                                    Text(failedRules[index].description)
                                        .font(DSTypography.caption)
                                        .foregroundColor(DSColor.statusError)
                                }
                            }
                        }
                    }
                    
                    // Success message when all rules pass
                    if isPasswordValid {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DSColor.statusSuccess)
                                .font(.caption)
                            
                            Text("Password meets all requirements")
                                .font(DSTypography.caption)
                                .foregroundColor(DSColor.statusSuccess)
                        }
                    }
                }
                .padding(.top, DSSpacing.xs)
            }
        }
    }
    
    private var strengthLevel: Int {
        switch passwordStrength {
        case .weak: return 1
        case .fair: return 2
        case .good: return 3
        case .strong: return 4
        }
    }
    
    private var validationBorderColor: Color {
        if !showValidation || text.isEmpty {
            return isEditing ? DSColor.accent : DSColor.border.opacity(0.3)
        }
        
        if isPasswordValid {
            return DSColor.statusSuccess
        } else if text.count >= 3 {
            return passwordStrength.color
        } else {
            return isEditing ? DSColor.accent : DSColor.border.opacity(0.3)
        }
    }
    
    // MARK: - Computed Colors
    
    private var backgroundColor: Color {
        isEnabled ? Color.white : DSColor.disabledBackground
    }
    
    private var borderColor: Color {
        if isEditing {
            return DSColor.accent
        } else {
            return DSColor.border.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        isEnabled ? DSColor.textPrimary : DSColor.disabledText
    }
    
    private var iconColor: Color {
        isEnabled ? DSColor.textSecondary : DSColor.disabledText
    }
}
