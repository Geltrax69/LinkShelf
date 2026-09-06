import AppIntents
import AppKit
import Foundation
import WidgetKit

/// Move the widgets between the folder list, one folder, and the shelf each
/// widget is configured for. A widget has no state of its own, so the choice
/// lives in the shared library file.
struct BrowseIntent: AppIntent {
    static var title: LocalizedStringResource { "Browse LinkShelf" }
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Target") var target: String?

    init() {}
    init(target: String?) { self.target = target }

    func perform() async throws -> some IntentResult {
        var library = LibraryFile.load()
        library.browse = target
        try? LibraryFile.save(library)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Open a saved link in the browser. A widget's `Link` hands the URL to the
/// containing app instead, which is not what anyone wants from a link shelf.
struct OpenLinkIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Link" }
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Address") var address: String

    init() {}
    init(address: String) { self.address = address }

    func perform() async throws -> some IntentResult {
        if let url = URL(string: address) { NSWorkspace.shared.open(url) }
        return .result()
    }
}

/// Ask the app to open its Add Link box, filled in from the clipboard when it
/// holds a web address. A widget cannot host a text field of its own.
struct AddPastedLinkIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Link" }
    static var description: IntentDescription { "Opens LinkShelf's Add Link box for this shelf." }
    /// Runs in the app: only the app has a text field, and a sandboxed
    /// extension reads the clipboard as empty anyway.
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Folder") var folderID: String?

    init() {}
    init(folderID: String?) { self.folderID = folderID }

    @MainActor
    func perform() async throws -> some IntentResult {
        AddLinkRequest.post(folderID: folderID.flatMap(UUID.init(uuidString:)))
        return .result()
    }
}

/// Handed from the widget's + button to whichever window is open.
enum AddLinkRequest {
    static let didPost = Notification.Name("LinkShelfAddLinkRequest")
    /// Set just before the notification; the sheet reads it when it appears.
    nonisolated(unsafe) static var folderID: UUID?

    @MainActor static func post(folderID: UUID?) {
        Self.folderID = folderID
        NotificationCenter.default.post(name: didPost, object: nil)
    }
}

/// Folders need a name, and a widget has nowhere to type one — so this asks
/// for it and then creates the folder without opening the window.
struct NewFolderIntent: AppIntent {
    static var title: LocalizedStringResource { "New Folder" }
    static var description: IntentDescription { "Opens a box to name a new folder." }
    /// Same reason as Add Link: a widget has nowhere to type a name.
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        NewFolderRequest.post()
        return .result()
    }
}

enum NewFolderRequest {
    static let didPost = Notification.Name("LinkShelfNewFolderRequest")

    @MainActor static func post() {
        NotificationCenter.default.post(name: didPost, object: nil)
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
