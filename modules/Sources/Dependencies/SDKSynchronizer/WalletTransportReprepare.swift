//
//  WalletTransportReprepare.swift
//  stealth
//
//  Drop and rebuild DarkfiWalletHandle after Tor/Nym/Direct or server changes
//  so Rust picks up the new SOCKS route / endpoint (stop+start alone reuses the old handle).
//

import DarkfiCore
import Foundation
import MnemonicClient
import Utils
import WalletStorage

public enum WalletTransportReprepare {
    public static func reprepareExisting(
        walletStorage: WalletStorageClient,
        sdkSynchronizer: SDKSynchronizerClient,
        mnemonic: MnemonicClient
    ) async throws {
        sdkSynchronizer.stop()
        TransportHooks.onNetworkChanged()
        let storedWallet = try walletStorage.exportWallet()
        let birthday = storedWallet.birthday?.value() ?? 0
        let seedBytes = try mnemonic.toSeed(storedWallet.seedPhrase.value())
        try await sdkSynchronizer.prepareWith(seedBytes, birthday, .existingWallet)
        try await sdkSynchronizer.start(false)
    }
}
