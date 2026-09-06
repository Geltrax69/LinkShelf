import AppIntents
import AppKit
import Foundation
import WidgetKit

/// Save whatever URL is on the clipboard straight into the shelf the widget
/// is showing. A widget cannot host a text field, so the clipboard is the only
/// way to get a link in without opening the app.
struct AddPastedLinkIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Link from Clipboard" }
    static var description: IntentDescription { "Saves the copied web address to this shelf." }

    @Parameter(title: "Folder") var folderID: String?

    init() {}
    init(folderID: String?) { self.folderID = folderID }

    func perform() async throws -> some IntentResult {
        guard let text = NSPasteboard.general.string(forType: .string),
              let url = LinkNormalizer.normalize(text) else { return .result() }

        var library = LibraryFile.load()
        guard !library.links.contains(where: { $0.url == url && !$0.trashed }) else { return .result() }

        let link = SavedLink(url: url,
                             title: url.host()?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString,
                             folderID: folderID.flatMap(UUID.init(uuidString:)))
        library.links.insert(link, at: 0)
        try? LibraryFile.save(library)
        WidgetCenter.shared.reloadAllTimelines()

        // Then fill in the title and preview, which needs the network.
        let metadata = await LinkMetadata.fetch(for: url)
        var updated = LibraryFile.load()
        guard let index = updated.links.firstIndex(where: { $0.id == link.id }) else { return .result() }
        if let title = metadata.title { updated.links[index].title = title }
        if let image = metadata.image {
            try? FileManager.default.createDirectory(at: LibraryFile.thumbnailsDirectory, withIntermediateDirectories: true)
            try? image.write(to: LibraryFile.thumbnail(for: link.id), options: .atomic)
            updated.links[index].thumbnailStamp = Date()
        }
        try? LibraryFile.save(updated)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Folders need a name, and a widget has nowhere to type one — so this asks
/// for it and then creates the folder without opening the window.
struct NewFolderIntent: AppIntent {
    static var title: LocalizedStringResource { "New LinkShelf Folder" }
    static var description: IntentDescription { "Creates a folder in your library." }

    @Parameter(title: "Folder name", requestValueDialog: "What should the folder be called?")
    var name: String

    init() {}
    init(name: String) { self.name = name }

    func perform() async throws -> some IntentResult {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return .result() }
        var library = LibraryFile.load()
        guard !library.folders.contains(where: { $0.name.localizedCaseInsensitiveCompare(clean) == .orderedSame }) else {
            return .result()
        }
        library.folders.append(Folder(name: clean))
        try? LibraryFile.save(library)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct LinkShelfShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: NewFolderIntent(),
                    phrases: ["Create a folder in \(.applicationName)"],
                    shortTitle: "New Folder",
                    systemImageName: "folder.badge.plus")
        AppShortcut(intent: AddPastedLinkIntent(),
                    phrases: ["Save my clipboard to \(.applicationName)"],
                    shortTitle: "Add Link",
                    systemImageName: "plus")
    }
}
