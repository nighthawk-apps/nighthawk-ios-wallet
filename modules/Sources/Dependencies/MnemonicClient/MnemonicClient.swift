//
//  MnemonicClient.swift
//
//
//  Created by Matthew Watt on 9/29/23.
//

import ComposableArchitecture
import Foundation
import MnemonicSwift

public struct MnemonicClient {
    /// Random 24 words mnemonic phrase
    public var randomMnemonic: () throws -> String
    /// Random 24 words mnemonic phrase as array of words
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
            try Mnemonic.generateMnemonic(strength: 256)
        },
        randomMnemonicWords: {
            try Mnemonic.generateMnemonic(
                strength: 256
            ).components(separatedBy: " ")
        },
        toSeed: { mnemonic in
            let data = try Mnemonic.deterministicSeedBytes(from: mnemonic)

            return [UInt8](data)
        },
        asWords: { mnemonic in
            mnemonic.components(separatedBy: " ")
        },
        isValid: { mnemonic in
            do {
                try Mnemonic.validate(mnemonic: mnemonic)
                return true
            } catch {
                return false
            }
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
