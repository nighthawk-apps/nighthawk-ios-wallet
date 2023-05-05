//
//  TCALogging.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 23.01.2023.
//

#if !SECANT_MAINNET_NO_LOGGING
import Foundation
import os
import ZcashLightClientKit

extension OSLogger {
    static let live = OSLogger(logLevel: .debug, category: LoggerConstants.tcaLogs)

    func tcaDebug(_ message: String) {
        guard let oslog else { return }
        
        os_log(
            "%{public}@",
            log: oslog,
            message
        )
    }
}
#endif
