import CryptoKit
import Foundation
import Security

/// AES-GCM encryption for data at rest, keyed by a 256-bit symmetric key that
/// lives in the Keychain. The key is generated on first use and never leaves
/// the device unencrypted; `kSecAttrAccessibleAfterFirstUnlock` keeps it
/// readable for background writes while still riding along in encrypted
/// device backups, so restored data remains decryptable.
struct DataCipher {
    enum CipherError: Error {
        case keychainFailure(OSStatus)
        case sealFailure
    }

    private let key: SymmetricKey

    init(keychainAccount: String = "com.mewp.storage-key") throws {
        self.key = try Self.loadOrCreateKey(account: keychainAccount)
    }

    /// Encrypts plaintext into a single blob (nonce + ciphertext + tag).
    func seal(_ plaintext: Data) throws -> Data {
        guard let combined = try AES.GCM.seal(plaintext, using: key).combined else {
            throw CipherError.sealFailure
        }
        return combined
    }

    /// Decrypts a blob produced by `seal`. Throws if the data was tampered
    /// with or encrypted under a different key.
    func open(_ ciphertext: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }

    // MARK: - Key management

    private static func loadOrCreateKey(account: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return SymmetricKey(data: data)
        }
        guard status == errSecItemNotFound else {
            throw CipherError.keychainFailure(status)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: keyData,
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CipherError.keychainFailure(addStatus)
        }
        return key
    }
}
