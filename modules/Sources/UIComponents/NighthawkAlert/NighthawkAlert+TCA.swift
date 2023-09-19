//
//  NighthawkAlert+TCA.swift
//  
//
//  Created by Matthew Watt on 9/8/23.
//

// NOTE: This is internal API to TCA, so it could break in the future unexpectedly
//       It seems that this is the only option (and sanctioned by the authors) for hooking custom views into the TCA @PresentationState mechanism
//       See this discussion for more info (https://github.com/pointfreeco/swift-composable-architecture/discussions/2007#discussioncomment-6286992)
@_spi(Presentation) import ComposableArchitecture
import SwiftUI

extension View {
    public func nighthawkAlert<State, Action, Content: View>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        @ViewBuilder content: @escaping (_ store: Store<State, Action>) -> Content
    ) -> some View {
        self.presentation(store: store) { `self`, $item, destination in
            self.nighthawkAlert(unwrapping: $item) { _ in
                destination(content)
            }
        }
    }
    
    public func nighthawkAlert<State, Action, DestinationState, DestinationAction, Content: View>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (_ state: State) -> DestinationState?,
        action fromDestinationAction: @escaping (_ destinationAction: DestinationAction) -> Action,
        @ViewBuilder content: @escaping (_ store: Store<DestinationState, DestinationAction>) -> Content
    ) -> some View {
        self.presentation(
            store: store, state: toDestinationState, action: fromDestinationAction
        ) { `self`, $item, destination in
            self.nighthawkAlert(unwrapping: $item) { _ in
                destination(content)
            }
        }
    }
}
