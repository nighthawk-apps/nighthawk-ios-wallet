//
//  App+Alerts.swift
//  
//
//  Created by Matthew Watt on 9/12/23.
//

import ComposableArchitecture
import Utils
import Generated

extension AlertState where Action == AppReducer.Action.Alert {
    public static func cantCreateNewWallet(_ error: DarkFiError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.Welcome.Initialization.Alert.Failed.title)
        } message: {
            TextState(L10n.Nighthawk.Welcome.Initialization.Alert.CantCreateNewWallet.message(error.message, 0))
        }
    }
    
    public static func sdkInitFailed(_ error: DarkFiError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.App.Launch.Alert.SdkInitFailed.title)
        } message: {
            TextState(L10n.Nighthawk.App.Launch.Alert.Error.message(error.message, 0))
        }
    }
    
    public static func notEnoughFreeDiskSpace() -> AlertState {
        AlertState {
            TextState(L10n.Nefs.message)
        }
    }
    
    public static func deleteWalletFailed() -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.App.DeleteWallet.Alert.Failed.title)
        }
    }
}
