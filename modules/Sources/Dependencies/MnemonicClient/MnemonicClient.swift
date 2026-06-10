//
//  MnemonicClient.swift
//
//
//  Created by Matthew Watt on 9/29/23.
//

import ComposableArchitecture
import Foundation
import DarkfiCore

public struct MnemonicClient {
    /// Random 22-word DarkFi mnemonic phrase
    public var randomMnemonic: () throws -> String
    /// Random 22-word DarkFi mnemonic phrase as array of words
    public var randomMnemonicWords: () throws -> [String]
    /// Generate deterministic seed from mnemonic phrase
    public var toSeed: (String) throws -> [UInt8]
    /// Get this mnemonic phrase as array of words
    public var asWords: (String) -> [String]
    /// Validates whether the given mnemonic is correct
    public var isValid: (String) -> Bool
}

extension MnemonicClient: DependencyKey {
    public static let liveValue = Self(
        randomMnemonic: {
            generateDarkfiMnemonic().joined(separator: " ")
        },
        randomMnemonicWords: {
            generateDarkfiMnemonic()
        },
        toSeed: { mnemonic in
            // DarkFi uses the mnemonic phrase directly (not a derived seed).
            // Encode the phrase as UTF-8 bytes so WalletHandleManager can
            // reconstruct the word list from the stored wallet.
            return Array(mnemonic.utf8)
        },
        asWords: { mnemonic in
            mnemonic.components(separatedBy: " ")
        },
        isValid: { mnemonic in
            validateDarkfiMnemonic(phrase: mnemonic.components(separatedBy: " "))
        }
    )
}

extension MnemonicClient {
    public static let mock = MnemonicClient(
        randomMnemonic: {
            """
            still champion voice habit trend flight \
            survey between bitter process artefact blind \
            carbon truly provide dizzy crush flush \
            breeze blouse charge solid fish spread
            """
        },
        randomMnemonicWords: {
            let mnemonic = """
                still champion voice habit trend flight \
                survey between bitter process artefact blind \
                carbon truly provide dizzy crush flush \
                breeze blouse charge solid fish spread
                """
            
            return mnemonic.components(separatedBy: " ")
        },
        toSeed: { _ in
            let seedString = Data(
                base64Encoded: "9VDVOZZZOWWHpZtq1Ebridp3Qeux5C+HwiRR0g7Oi7HgnMs8Gfln83+/Q1NnvClcaSwM4ADFL1uZHxypEWlWXg=="
            )!// swiftlint:disable:this force_unwrapping
            
            return [UInt8](seedString)
        },
        asWords: { mnemonic in
            let mnemonic = """
                still champion voice habit trend flight \
                survey between bitter process artefact blind \
                carbon truly provide dizzy crush flush \
                breeze blouse charge solid fish spread
                """
            
            return mnemonic.components(separatedBy: " ")
        },
        isValid: { _ in true }
    )
}

extension DependencyValues {
    public var mnemonic: MnemonicClient {
        get { self[MnemonicClient.self] }
        set { self[MnemonicClient.self] = newValue }
    }
}
