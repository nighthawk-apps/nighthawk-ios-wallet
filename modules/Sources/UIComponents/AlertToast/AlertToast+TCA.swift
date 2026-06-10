//
//  AlertToast+TCA.swift
//
//
//  Created by Matthew Watt on 7/17/23.
//

import AlertToast
import ComposableArchitecture
import SwiftUI

public extension AlertToast {
    /// Banner toasts avoid the full-screen invisible overlay that `.alert`
    /// display mode installs even while the toast is hidden.
    static func nighthawkBanner(
        type: AlertType,
        title: String
    ) -> AlertToast {
        AlertToast(displayMode: .banner(.slide), type: type, title: title)
    }
}

// MARK: - Safe toast modifier
//
// The AlertToast package's `.toast(isPresenting:)` modifier always installs a
// full-size overlay `ZStack`, which blocks every tap on the underlying view —
// including the home tab bar — even when nothing is visible. We only mount a
// bottom banner while a toast is actually showing.

private struct NighthawkToastModifier: ViewModifier {
    @Binding var isPresenting: Bool
    let duration: Double
    let tapToDismiss: Bool
    let offsetY: CGFloat
    let alert: () -> AlertToast

    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresenting {
                    alert()
                        .onTapGesture {
                            if tapToDismiss {
                                dismiss()
                            }
                        }
                        .padding(.bottom, max(16, offsetY))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: isPresenting)
            .onChange(of: isPresenting) { _, presented in
                if presented {
                    scheduleAutoDismissIfNeeded()
                } else {
                    workItem?.cancel()
                    workItem = nil
                }
            }
    }

    private func dismiss() {
        withAnimation(.spring()) {
            isPresenting = false
        }
    }

    private func scheduleAutoDismissIfNeeded() {
        guard duration > 0 else { return }

        workItem?.cancel()
        let task = DispatchWorkItem {
            dismiss()
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

extension View {
    func nighthawkToast(
        isPresenting: Binding<Bool>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> AlertToast
    ) -> some View {
        modifier(
            NighthawkToastModifier(
                isPresenting: isPresenting,
                duration: duration,
                tapToDismiss: tapToDismiss,
                offsetY: offsetY,
                alert: alert
            )
        )
    }

    public func toast<Value>(
        unwrapping value: Binding<Value?>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (Value) -> AlertToast
    ) -> some View {
        nighthawkToast(
            isPresenting: Binding(
                get: { value.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        value.wrappedValue = nil
                    }
                }
            ),
            duration: duration,
            tapToDismiss: tapToDismiss,
            offsetY: offsetY,
            alert: {
                if let value = value.wrappedValue {
                    alert(value)
                } else {
                    AlertToast.nighthawkBanner(type: .regular, title: "")
                }
            }
        )
    }

    public func toast<Enum, Case>(
        unwrapping enum: Binding<Enum?>,
        case casePath: AnyCasePath<Enum, Case>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (Case) -> AlertToast,
        onTap: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> some View {
        toast(
            unwrapping: `enum`.case(casePath),
            duration: duration,
            tapToDismiss: tapToDismiss,
            offsetY: offsetY,
            alert: alert
        )
    }
}
