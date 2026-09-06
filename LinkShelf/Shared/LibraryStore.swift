import AppKit
import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class LibraryStore {
    private(set) var library = LibraryFile.load()
    var lastError: String?

    init() {
        // Retry anything whose preview never arrived (offline, slow site).
        for link in library.links where link.thumbnailStamp == nil && !link.trashed {
            Task { await fetchMetadata(for: link.id) }
        }
    }

    var folders: [Folder] { library.folders.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } }

    func links(in section: LibrarySection) -> [SavedLink] {
        let all = library.links
        let live = all.filter { !$0.trashed && !$0.archived }
        switch section {
        case .destination(.all): return live.sorted { $0.added > $1.added }
        case .destination(.favorites): return live.filter(\.favorite).sorted { $0.added > $1.added }
        case .destination(.recent): return Array(live.sorted { $0.added > $1.added }.prefix(20))
        case .destination(.archive): return all.filter { $0.archived && !$0.trashed }.sorted { $0.added > $1.added }
        case .destination(.trash): return all.filter(\.trashed).sorted { $0.added > $1.added }
        case .folder(let id): return live.filter { $0.folderID == id }.sorted { $0.added > $1.added }
        }
    }

    // MARK: - Mutations

    @discardableResult
    func addLink(_ text: String, folderID: UUID? = nil) -> SavedLink? {
        guard let url = LinkNormalizer.normalize(text) else {
            lastError = "“\(text.prefix(60))” is not a web address."
            return nil
        }
        if let existing = library.links.firstIndex(where: { $0.url == url && !$0.trashed }) {
            lastError = "That link is already on your shelf."
            library.links[existing].added = Date()
            save()
            return library.links[existing]
        }
        let link = SavedLink(url: url, title: url.host()?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString, folderID: folderID)
        library.links.insert(link, at: 0)
        lastError = nil
        save()
        Task { await fetchMetadata(for: link.id) }
        return link
    }

    func addFolder(named name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard !library.folders.contains(where: { $0.name.localizedCaseInsensitiveCompare(clean) == .orderedSame }) else {
            lastError = "A folder named “\(clean)” already exists."
            return
        }
        library.folders.append(Folder(name: clean))
        lastError = nil
        save()
    }

    func setSymbol(_ symbol: String, for folder: Folder) {
        guard let index = library.folders.firstIndex(where: { $0.id == folder.id }) else { return }
        library.folders[index].symbol = symbol
        library.folders[index].iconStamp = nil
        try? FileManager.default.removeItem(at: LibraryFile.icon(for: folder.id))
        save()
    }

    /// Any image the user picks becomes a small square JPEG in the container,
    /// so the widget can draw it without reaching outside its sandbox.
    func setIcon(from file: URL, for folder: Folder) {
        guard let data = try? Data(contentsOf: file),
              let small = LinkMetadata.downsampled(data, maxWidth: 128) else {
            lastError = "That file is not an image LinkShelf can read."
            return
        }
        guard let index = library.folders.firstIndex(where: { $0.id == folder.id }) else { return }
        try? FileManager.default.createDirectory(at: LibraryFile.iconsDirectory, withIntermediateDirectories: true)
        try? small.write(to: LibraryFile.icon(for: folder.id), options: .atomic)
        library.folders[index].iconStamp = Date()
        save()
    }

    func deleteFolder(_ folder: Folder) {
        library.folders.removeAll { $0.id == folder.id }
        try? FileManager.default.removeItem(at: LibraryFile.icon(for: folder.id))
        for index in library.links.indices where library.links[index].folderID == folder.id {
            library.links[index].folderID = nil
        }
        save()
    }

    func move(_ link: SavedLink, to folderID: UUID?) { update(link) { $0.folderID = folderID } }
    func toggleFavorite(_ link: SavedLink) { update(link) { $0.favorite.toggle() } }
    func archive(_ link: SavedLink) { update(link) { $0.archived = true } }
    func trash(_ link: SavedLink) { update(link) { $0.trashed = true } }
    func restore(_ link: SavedLink) { update(link) { $0.trashed = false; $0.archived = false } }

    func deleteForever(_ link: SavedLink) {
        library.links.removeAll { $0.id == link.id }
        try? FileManager.default.removeItem(at: LibraryFile.thumbnail(for: link.id))
        save()
    }

    private func update(_ link: SavedLink, _ change: (inout SavedLink) -> Void) {
        guard let index = library.links.firstIndex(where: { $0.id == link.id }) else { return }
        change(&library.links[index])
        save()
    }

    private func save() {
        do {
            try LibraryFile.save(library)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            lastError = "Could not save your library: \(error.localizedDescription)"
        }
    }

    private func fetchMetadata(for id: UUID) async {
        guard let link = library.links.first(where: { $0.id == id }) else { return }
        let metadata = await LinkMetadata.fetch(for: link.url)
        if let title = metadata.title { update(link) { $0.title = title } }
        guard let image = metadata.image else { return }
        try? FileManager.default.createDirectory(at: LibraryFile.thumbnailsDirectory, withIntermediateDirectories: true)
        try? image.write(to: LibraryFile.thumbnail(for: id), options: .atomic)
        update(link) { $0.thumbnailStamp = Date() }
    }

}
