import Foundation

public struct DarkfiChatIdentity {
    public let nickname: String
    public let mnemonic: [String]
    public let entropyBytes: [UInt8]?
    public let dmKeypair: DmKeypair?
    
    public init(nickname: String, mnemonic: [String]) {
        self.nickname = nickname
        self.mnemonic = mnemonic
        
        // Use Rust FFI to decode
        self.entropyBytes = decodeChatEntropy(phrase: mnemonic)
        
        // Generate a ChaCha box keypair for DMs using the rust generator
        self.dmKeypair = generateDmKeypair()
    }
    
    public static func createNew(nickname: String) -> DarkfiChatIdentity {
        let phrase = generateBip39ChatMnemonic()
        return DarkfiChatIdentity(nickname: nickname, mnemonic: phrase)
    }
}

public class DarkfiChatCrypto {
    public static func encryptDM(mySecret: [UInt8], theirPublic: [UInt8], plaintext: String) throws -> String {
        return try chachaEncryptDm(mySecret: mySecret, theirPublic: theirPublic, plaintext: plaintext)
    }
    
    public static func decryptDM(mySecret: [UInt8], theirPublic: [UInt8], ciphertextB58: String) throws -> String {
        return try chachaDecryptDm(mySecret: mySecret, theirPublic: theirPublic, ciphertextB58: ciphertextB58)
    }
}
