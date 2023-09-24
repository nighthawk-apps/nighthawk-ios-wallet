//
//  Home+Alerts.swift
//
//
//  Created by Matthew Watt on 9/23/23.
//

import ComposableArchitecture
import Generated
import ZcashLightClientKit

extension AlertState where Action == Home.Destination.Action.Alert {
    public static func notEnoughFreeDiskSpace() -> AlertState {
        AlertState {
            TextState(L10n.Nefs.message)
        }
    }
}
