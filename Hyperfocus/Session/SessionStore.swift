// SessionStore.swift — JSON persistence of [Session] at Application Support/Hyperfocus/sessions.json (canon §7).

import Foundation

final class SessionStore {
    private let directoryURL: URL
    private var fileURL: URL { directoryURL.appendingPathComponent(Constants.Storage.fileName) }

    /// Injectable directory URL for tests; defaults to ~/Library/Application Support/Hyperfocus.
    init(directoryURL: URL = SessionStore.defaultDirectoryURL()) {
        self.directoryURL = directoryURL
    }

    static func defaultDirectoryURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent(Constants.Storage.directoryName, isDirectory: true)
    }

    func all() -> [Session] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Session].self, from: data)) ?? []
    }

    func append(_ session: Session) throws {
        var sessions = all()
        sessions.append(session)
        try write(sessions)
    }

    func clear() throws {
        try write([])
    }

    private func write(_ sessions: [Session]) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sessions)
        try data.write(to: fileURL, options: .atomic)
    }
}
