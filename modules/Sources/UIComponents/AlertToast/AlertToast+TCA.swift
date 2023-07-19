//
//  AlertToast+TCA.swift
//  
//
//  Created by Matthew Watt on 7/17/23.
//

import AlertToast
import SwiftUI
import SwiftUINavigation

extension View {
    public func toast<Value>(
        unwrapping value: Binding<Value?>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (Value) -> AlertToast
    ) -> some View {
        self.toast(
            isPresenting: value.isPresent(),
            duration: duration,
            tapToDismiss: tapToDismiss,
            offsetY: offsetY,
            alert: {
                value.wrappedValue.map(alert) ?? AlertToast(
                    type: .regular,
                    title: ""
                )
            }
        )
    }
    
    public func toast<Enum, Case>(
        unwrapping enum: Binding<Enum?>,
        case casePath: CasePath<Enum, Case>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (Case) -> AlertToast,
        onTap: (() -> ())? = nil,
        completion: (() -> ())? = nil
    ) -> some View {
        self.toast(
            unwrapping: `enum`.case(casePath),
            duration: duration,
            tapToDismiss: tapToDismiss,
            offsetY: offsetY,
            alert: alert
        )
    }
}
