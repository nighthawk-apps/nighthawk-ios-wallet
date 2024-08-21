//
//  Home+Alerts.swift
//
//
//  Created by Matthew Watt on 9/23/23.
//

import ComposableArchitecture
import Generated
import ZcashLightClientKit

extension AlertState where Action == Home.Action.Alert {
    public static func cantStartSync(_ error: ZcashError) -> AlertState {
            AlertState {
                TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.CantStartSync.title)
            } message: {
                TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.CantStartSync.message(error.message, error.code.rawValue))
            }
        }
    
    public static func notEnoughFreeDiskSpace() -> AlertState {
        AlertState {
            TextState(L10n.Nefs.message)
        }
    }
    
    public static func rescanFailed(_ error: ZcashError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.Alert.Rescan.Failed.message(error.message, error.code.rawValue))
        }
    }
}
