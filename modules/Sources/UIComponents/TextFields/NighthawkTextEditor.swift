//
//  NighthawkTextEditor.swift
//  secant
//
//  Created by Matthew Watt on 5/13/23.
//

import CasePaths
import Generated
import SwiftUI

public struct NighthawkTextEditor: View {
    
    @CasePathable
    public enum ValidationState: Equatable {
        case valid
        case invalid(error: String)
    }
    
    private var placeholder: String?
    private var text: Binding<String>
    private var isValid: NighthawkTextEditor.ValidationState
    private var foregroundColor: Color
    
    public init(
        placeholder: String? = nil,
        text: Binding<String>,
        isValid: NighthawkTextEditor.ValidationState = .valid,
        foregroundColor: Color = Asset.Colors.Nighthawk.peach.color
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isValid = isValid
        self.foregroundColor = foregroundColor
    }
    
    @FocusState private var _focusState: Bool
    @State private var _dirty = false
    
    public var body: some View {
        let errorMessage = isValid[case: \.invalid]
        let isError = errorMessage != nil
        let showError = isError && _dirty && !_focusState
        
        return VStack(alignment: .leading, spacing: 8) {
            Group {
                TextEditor(text: text)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                    .focused($_focusState)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                _focusState || !text.wrappedValue.isEmpty
                                ? foregroundColor.opacity(0.8)
                                : Asset.Colors.Nighthawk.parmaviolet.color,
                                lineWidth: 2
                            )
                    )
            }
            .placeholder(when: text.wrappedValue.isEmpty) {
                if let placeholder {
                    Text(placeholder)
                        .subtitle(
                            color: _focusState || !text.wrappedValue.isEmpty
                            ? foregroundColor.opacity(0.8)
                            : Asset.Colors.Nighthawk.parmaviolet.color
                        )
                        .padding(.leading, 14)
                        .padding(.top, 18)
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
        ZStack(alignment: .topLeading) {
            self
            placeholder().opacity(shouldShow ? 1 : 0).allowsHitTesting(false)
        }
    }
}
