import Foundation
import Observation

/// Holds the user's pay rate and writes it back to disk on every change.
/// The rate is AES-GCM encrypted before it lands in UserDefaults, with the
/// key kept in the Keychain (see `DataCipher`).
@Observable
final class PaySettingsStore {
    private static let storageKey = "pay_rate_v1"
    private static let onboardedKey = "has_set_rate_v1"

    var rate: PayRate {
        didSet { persist() }
    }

    /// False until the user has saved a rate at least once, so the first launch
    /// can send them to Settings instead of showing a meter set to a guess.
    private(set) var hasSetRate: Bool

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cipher: DataCipher?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Keychain access can fail in rare cases; running unencrypted beats
        // wiping the user's saved rate.
        self.cipher = try? DataCipher()

        var loaded: PayRate?
        var needsMigration = false
        if let data = defaults.data(forKey: Self.storageKey) {
            let decoder = JSONDecoder()
            if let cipher,
               let plaintext = try? cipher.open(data),
               let decoded = try? decoder.decode(PayRate.self, from: plaintext) {
                loaded = decoded
            } else if let decoded = try? decoder.decode(PayRate.self, from: data) {
                // Plaintext blob from an older version; re-save it encrypted.
                loaded = decoded
                needsMigration = true
            }
        }
        self.rate = loaded ?? PayRate()
        self.hasSetRate = defaults.bool(forKey: Self.onboardedKey)

        if needsMigration {
            persist()
        }
    }

    /// Call when the user finishes editing, not on every keystroke.
    func markConfigured() {
        guard !hasSetRate else { return }
        hasSetRate = true
        defaults.set(true, forKey: Self.onboardedKey)
    }

    private func persist() {
        guard var data = try? JSONEncoder().encode(rate) else { return }
        if let cipher, let sealed = try? cipher.seal(data) {
            data = sealed
        }
        defaults.set(data, forKey: Self.storageKey)
    }
}
