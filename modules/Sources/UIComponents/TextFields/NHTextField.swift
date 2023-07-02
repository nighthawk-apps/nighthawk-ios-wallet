//
//  NHTextField.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import CasePaths
import Generated
import SwiftUI

public struct NHTextField: View {
    public enum ValidationState: Equatable {
        case valid
        case invalid(error: String)
    }
    
    private var placeholder: String?
    private var text: Binding<String>
    private var isValid: NHTextField.ValidationState
    
    public init(
        placeholder: String? = nil,
        text: Binding<String>,
        isValid: NHTextField.ValidationState = .valid
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isValid = isValid
    }
    
    @FocusState private var _focusState: Bool
    @State private var _dirty = false
    
    public var body: some View {
        let errorMessage = (/NHTextField.ValidationState.invalid).extract(from: isValid)
        let isError = errorMessage != nil
        let showError = isError && _dirty && !_focusState
        
        return VStack(alignment: .leading, spacing: 8) {
            Group {
                TextField("", text: text)
                    .foregroundColor(.white)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                    .focused($_focusState)
                    
            }
            .textFieldStyle(
                .nighthawk(
                    isEmpty: text.wrappedValue.isEmpty,
                    isFocused: _focusState,
                    isError: showError
                )
            )
            .placeholder(when: text.wrappedValue.isEmpty) {
                if let placeholder {
                    Text(placeholder)
                        .subtitle(
                            color: _focusState || !text.wrappedValue.isEmpty
                            ? Asset.Colors.Nighthawk.peach.color.opacity(0.8)
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

private struct _NighthawkTextFieldStyle: TextFieldStyle {
    var isEmpty: Bool
    var isFocused: Bool
    var isError: Bool
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isError
                    ? Asset.Colors.Nighthawk.error.color
                    : isFocused || !isEmpty
                    ? Asset.Colors.Nighthawk.peach.color.opacity(0.8)
                    : Asset.Colors.Nighthawk.parmaviolet.color,
                    lineWidth: 2
                )
                .frame(height: 56)
            
            configuration
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.leading, 16)
        }
    }
}

private extension TextFieldStyle where Self == _NighthawkTextFieldStyle {
    static func nighthawk(
        isEmpty: Bool,
        isFocused: Bool,
        isError: Bool = false
    ) -> _NighthawkTextFieldStyle {
        _NighthawkTextFieldStyle(
            isEmpty: isEmpty,
            isFocused: isFocused,
            isError: isError
        )
    }
}
