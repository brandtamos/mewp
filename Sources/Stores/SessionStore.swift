import Foundation
import Observation

/// Session history, stored as an AES-GCM encrypted JSON file in Documents.
/// Fine up to a few thousand records; move to SwiftData if you add syncing
/// or charts over years.
@Observable
final class SessionStore {
    private(set) var sessions: [BreakSession] = []

    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let cipher: DataCipher?

    init(filename: String = "sessions.json") {
        let directory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = directory.appendingPathComponent(filename)
        // Keychain access can fail in rare cases (e.g. device locked during a
        // background launch). Better to run unencrypted than to lose history.
        self.cipher = try? DataCipher()
        load()
    }

    // MARK: - Mutations

    func add(_ session: BreakSession) {
        sessions.insert(session, at: 0)
        persist()
    }

    func update(_ session: BreakSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        sessions.sort { $0.endedAt > $1.endedAt }
        persist()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persist()
    }

    func removeAll() {
        sessions.removeAll()
        persist()
    }

    // MARK: - Stats

    var totalEarnings: Decimal {
        sessions.reduce(0) { $0 + $1.earnings }
    }

    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var averageDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalDuration / Double(sessions.count)
    }

    var longest: BreakSession? {
        sessions.max { $0.duration < $1.duration }
    }

    func sessions(on day: Date, calendar: Calendar = .current) -> [BreakSession] {
        sessions.filter { calendar.isDate($0.endedAt, inSameDayAs: day) }
    }

    /// True if the given time range overlaps any saved session. Pass the id of
    /// the session being edited to `excluding` so it doesn't clash with itself.
    /// Touching endpoints (one trip ending exactly when the next begins) is
    /// allowed — the comparison is strict.
    func overlaps(start: Date, end: Date, excluding id: UUID? = nil) -> Bool {
        sessions.contains { session in
            guard session.id != id else { return false }
            return start < session.endedAt && session.startedAt < end
        }
    }

    var earningsToday: Decimal {
        sessions(on: .now).reduce(0) { $0 + $1.earnings }
    }

    // MARK: - Disk

    private func load() {
        guard let raw = try? Data(contentsOf: fileURL) else { return }

        // Prefer the encrypted format; fall back to plaintext JSON written by
        // older versions and immediately re-save it encrypted.
        let decoder = JSONDecoder()
        if let cipher,
           let plaintext = try? cipher.open(raw),
           let decoded = try? decoder.decode([BreakSession].self, from: plaintext) {
            sessions = decoded.sorted { $0.endedAt > $1.endedAt }
        } else if let decoded = try? decoder.decode([BreakSession].self, from: raw) {
            sessions = decoded.sorted { $0.endedAt > $1.endedAt }
            persist() // migrate legacy plaintext file to encrypted format
        }
    }

    private func persist() {
        do {
            var data = try JSONEncoder().encode(sessions)
            if let cipher {
                data = try cipher.seal(data)
            }
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            // Losing a bathroom break is survivable. Log and move on.
            print("SessionStore: failed to save — \(error)")
        }
    }
}
