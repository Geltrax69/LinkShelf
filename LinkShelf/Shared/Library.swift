import Foundation

struct Folder: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var symbol: String = "folder"
}

struct SavedLink: Codable, Identifiable, Hashable {
    var id = UUID()
    var url: URL
    var title: String
    var folderID: UUID?
    var added = Date()
    var favorite = false
    var archived = false
    var trashed = false
    /// Set when a preview image lands on disk; also what makes views refresh.
    var thumbnailStamp: Date?

    var host: String { url.host()?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString }

    /// Downloaded preview image, if one has been cached for this link.
    var thumbnailFile: URL? {
        guard thumbnailStamp != nil else { return nil }
        let file = LibraryFile.thumbnail(for: id)
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }
}

enum Thumbnails {
    /// YouTube publishes a predictable still for every video, so no page fetch.
    static func youTubeImageURL(for url: URL) -> URL? {
        let id: String?
        if url.host()?.contains("youtu.be") == true {
            id = url.pathComponents.dropFirst().first
        } else if url.host()?.contains("youtube.com") == true {
            id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "v" }?.value
        } else {
            id = nil
        }
        guard let id, !id.isEmpty else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }
}

struct Library: Codable {
    var folders: [Folder] = []
    var links: [SavedLink] = []
}

/// Shared JSON file, read by the app and the widget extension.
/// ponytail: one file, whole-library rewrite on every change. Fine for
/// thousands of links; move to SwiftData when a save is measurably slow.
enum LibraryFile {
    static let appGroup = "D676SQ267J.group.com.geltrax69.LinkShelf"

    static var url: URL {
        if let override = ProcessInfo.processInfo.environment["LINKSHELF_STORE"] {
            return URL(fileURLWithPath: override)
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "LinkShelf-uitest/library.json")
        }
        // Shared with the widget extension. Falls back to this process's own
        // Application Support when the App Group is unavailable.
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return group.appending(path: "library.json")
        }
        return URL.applicationSupportDirectory.appending(path: "LinkShelf/library.json")
    }

    static var thumbnailsDirectory: URL { url.deletingLastPathComponent().appending(path: "Thumbnails") }

    static func thumbnail(for id: UUID) -> URL { thumbnailsDirectory.appending(path: "\(id.uuidString).jpg") }

    static func load() -> Library {
        guard let data = try? Data(contentsOf: url),
              let library = try? JSONDecoder().decode(Library.self, from: data) else { return Library() }
        return library
    }

    static func save(_ library: Library) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(library).write(to: url, options: .atomic)
    }
}

enum LinkNormalizer {
    /// Accepts what people actually paste: bare hosts, whitespace, schemeless URLs.
    static func normalize(_ text: String) -> URL? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return nil }
        if !trimmed.contains("://") { trimmed = "https://" + trimmed }
        guard let url = URL(string: trimmed), let host = url.host(), host.contains("."),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}

