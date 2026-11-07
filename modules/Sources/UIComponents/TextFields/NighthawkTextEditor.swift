//
//  NighthawkTextEditor.swift
//  stealth
//
//  Created by Matthew Watt on 5/13/23.
//

import Generated
import SwiftUI

public struct NighthawkTextEditor: View {
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
        let errorMessage: String? = {
            if case let .invalid(error) = isValid { return error }
            return nil
        }()
        let isError = errorMessage != nil
        let showError = isError && _dirty && !_focusState

        return VStack(alignment: .leading, spacing: 8) {
            Group {
                TextEditor(text: text)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .scrollContentBackground(.hidden)
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                    .focused($_focusState)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Asset.Colors.Nighthawk.navy.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                showError
                                    ? Asset.Colors.Nighthawk.error.color
                                    : _focusState
                                    ? Asset.Colors.Nighthawk.peach.color
                                    : !text.wrappedValue.isEmpty
                                    ? foregroundColor.opacity(0.8)
                                    : Asset.Colors.Nighthawk.steelBorder.color,
                                lineWidth: _focusState || showError ? 1.5 : 1
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
            .onChange(of: _focusState) {
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
