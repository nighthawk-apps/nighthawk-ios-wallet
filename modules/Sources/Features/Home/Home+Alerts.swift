//
//  Home+Alerts.swift
//
//
//  Created by Matthew Watt on 9/23/23.
//

import ComposableArchitecture
import Generated
import Utils

extension AlertState where Action == Home.Action.Alert {
    public static func cantStartSync(_ error: DarkFiError) -> AlertState {
            AlertState {
                TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.CantStartSync.title)
            } message: {
                TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.CantStartSync.message(error.message, 0))
            }
        }
    
    public static func notEnoughFreeDiskSpace() -> AlertState {
        AlertState {
            TextState(L10n.Nefs.message)
        }
    }
    
    public static func rescanFailed(_ error: DarkFiError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.Failed.message(error.message, 0))
        }
    }
}
