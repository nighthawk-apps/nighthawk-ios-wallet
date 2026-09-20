import CryptoKit
import Foundation

/// App-side DarkFi address check. No UniFFI `validate_address` is exported, so
/// this mirrors `Address::from_str`: Base58Check → 37-byte
/// `[prefix][32-byte key][4-byte checksum]`, prefix `0x39` / `0xaf`.
public enum DarkfiAddressFormat {
    public static let mainnetPrefix: UInt8 = 0x39
    public static let testnetPrefix: UInt8 = 0xaf
    public static let decodedLength = 37

    public static func isValid(_ string: String, network: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let payload = decodeChecked(trimmed), payload.count == decodedLength else {
            return false
        }
        let prefix = payload[0]
        switch network.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "mainnet":
            return prefix == mainnetPrefix
        case "testnet":
            return prefix == testnetPrefix
        default:
            return prefix == mainnetPrefix || prefix == testnetPrefix
        }
    }

    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    static func decodeChecked(_ string: String) -> [UInt8]? {
        guard let raw = decodeBase58(string), raw.count >= 4 else { return nil }
        let payload = Array(raw.dropLast(4))
        let checksum = Array(raw.suffix(4))
        let hash = SHA256.hash(data: Data(SHA256.hash(data: Data(payload))))
        guard checksum.elementsEqual(hash.prefix(4)) else { return nil }
        return payload
    }

    private static func decodeBase58(_ string: String) -> [UInt8]? {
        var digits = [UInt8]()
        for char in string {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            var carry = index
            for j in 0..<digits.count {
                carry += Int(digits[j]) * 58
                digits[j] = UInt8(carry & 0xFF)
                carry >>= 8
            }
            while carry > 0 {
                digits.append(UInt8(carry & 0xFF))
                carry >>= 8
            }
        }
        for char in string {
            if char != "1" { break }
            digits.append(0)
        }
        return digits.reversed()
    }
}
