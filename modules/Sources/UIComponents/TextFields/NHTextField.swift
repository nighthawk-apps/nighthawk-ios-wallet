//
//  NHTextField.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import CasePaths
import Generated
import SwiftUI

public enum NHTextFieldValidationState: Equatable {
    case valid
    case invalid(error: String)
}

public struct NHTextField<InputAccessoryContent>: View where InputAccessoryContent: View {
    private var placeholder: String?
    private var text: Binding<String>
    private var isValid: NHTextFieldValidationState
    private let isSecure: Bool
    private let foregroundColor: Color
    private let inputAccessoryView: () -> InputAccessoryContent
    
    public init(
        placeholder: String? = nil,
        text: Binding<String>,
        isValid: NHTextFieldValidationState = .valid,
        isSecure: Bool = false,
        foregroundColor: Color = Asset.Colors.Nighthawk.peach.color,
        inputAccessoryView: @escaping () -> InputAccessoryContent = { EmptyView() }
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isValid = isValid
        self.isSecure = isSecure
        self.foregroundColor = foregroundColor
        self.inputAccessoryView = inputAccessoryView
    }
    
    @FocusState private var _focusState: Bool
    @State private var _dirty = false
    
    public var body: some View {
        let errorMessage = (/NHTextFieldValidationState.invalid).extract(from: isValid)
        let isError = errorMessage != nil
        let showError = isError && _dirty && !_focusState
        
        return VStack(alignment: .leading, spacing: 8) {
            Group {
                if isSecure {
                    SecureField("", text: text)
                        .foregroundColor(.white)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                        .focused($_focusState)
                } else {
                    TextField("", text: text)
                        .foregroundColor(.white)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                        .focused($_focusState)
                }
            }
            .textFieldStyle(
                _NighthawkTextFieldStyle(
                    isEmpty: text.wrappedValue.isEmpty,
                    isFocused: _focusState,
                    isError: showError,
                    foregroundColor: foregroundColor,
                    inputAccessoryView: inputAccessoryView
                )
            )
            .placeholder(when: text.wrappedValue.isEmpty) {
                if let placeholder {
                    Text(placeholder)
                        .subtitle(
                            color: _focusState || !text.wrappedValue.isEmpty
                            ? foregroundColor.opacity(0.8)
                            : Asset.Colors.Nighthawk.parmaviolet.color
                        )
                        .padding(.leading, 16)
                }
            }
            .onChange(of: _focusState) { _ in
                _dirty = true
            }
            
            HStack {
                Text(showError ? (errorMessage ?? "") : "")
                    .paragraph(color: Asset.Colors.Nighthawk.error.color)
            }
        }
    }
}

// MARK: - Implementation
private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            self
            placeholder().opacity(shouldShow ? 1 : 0).allowsHitTesting(false)
        }
    }
}

private struct _NighthawkTextFieldStyle<InputAccessoryContent>: TextFieldStyle where InputAccessoryContent: View {
    var isEmpty: Bool
    var isFocused: Bool
    var isError: Bool
    var foregroundColor: Color
    var inputAccessoryView: () -> InputAccessoryContent
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isError
                    ? Asset.Colors.Nighthawk.error.color
                    : isFocused || !isEmpty
                    ? foregroundColor.opacity(0.8)
                    : Asset.Colors.Nighthawk.parmaviolet.color,
                    lineWidth: 2
                )
                .frame(height: 56)
            
            HStack {
                configuration
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Spacer()
                
                inputAccessoryView()
            }
            .padding(.horizontal, 16)
        }
    }
}
