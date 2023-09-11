//
//  NighthawkAlert+SwiftUINavigation.swift
//  
//
//  Created by Matthew Watt on 9/8/23.
//

import CasePaths
import SwiftUI

extension View {
  public func nighthawkAlert<Content>(
    isActive: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
  where Content: View {
    self.modifier(
      NighthawkAlertModifier(
        isActive: isActive,
        content: content
      )
    )
  }

  public func nighthawkAlert<Value, Content>(
    unwrapping value: Binding<Value?>,
    @ViewBuilder content: @escaping (Binding<Value>) -> Content
  ) -> some View
  where Content: View {
    self.modifier(
      NighthawkAlertModifier(
        isActive: value.isPresent(),
        content: { Binding(unwrapping: value).map(content) }
      )
    )
  }

  public func nighthawkAlert<Enum, Case, Content>(
    unwrapping value: Binding<Enum?>,
    case casePath: CasePath<Enum, Case>,
    @ViewBuilder content: @escaping (Binding<Case>) -> Content
  ) -> some View
  where Content: View {
    self.nighthawkAlert(
      unwrapping: value.case(casePath),
      content: content
    )
  }
}
