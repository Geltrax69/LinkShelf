import Foundation

enum LibraryDestination: String, CaseIterable, Identifiable {
    case all, favorites, recent, archive, trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All Links"
        case .favorites: "Favorites"
        case .recent: "Recent"
        case .archive: "Archive"
        case .trash: "Trash"
        }
    }

    var symbol: String {
        switch self {
        case .all: "square.stack.3d.up"
        case .favorites: "star"
        case .recent: "clock"
        case .archive: "archivebox"
        case .trash: "trash"
        }
    }

    var emptyTitle: String {
        switch self {
        case .all: "Your links, in good company"
        case .favorites: "Keep the essentials close"
        case .recent: "Pick up where you left off"
        case .archive: "A little room for later"
        case .trash: "Nothing in the trash"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: "A home for the websites, ideas, and videos you want to come back to."
        case .favorites: "Your favorite links will have a place here, ready when you need them."
        case .recent: "Links you open will appear here, so your next visit is easy to find."
        case .archive: "Archived links will stay out of your way, without being forgotten."
        case .trash: "Links you remove will appear here before you delete them permanently."
        }
    }
}

enum LibraryLayout: String, CaseIterable, Identifiable {
    case grid, list
    var id: String { rawValue }
    var title: String { self == .grid ? "Grid view" : "List view" }
    var symbol: String { self == .grid ? "square.grid.2x2" : "list.bullet" }

    init(storedValue: String) { self = Self(rawValue: storedValue) ?? .grid }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    init(storedValue: String) { self = Self(rawValue: storedValue) ?? .system }
}

/// Sidebar selection: one of the fixed destinations, or a user folder.
enum LibrarySection: Hashable {
    case destination(LibraryDestination)
    case folder(UUID)
}
