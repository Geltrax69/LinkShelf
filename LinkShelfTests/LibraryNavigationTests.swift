import Foundation
import Testing
@testable import LinkShelf

struct LibraryNavigationTests {
    @Test func everyDestinationHasDistinctIdentityAndEmptyState() {
        #expect(Set(LibraryDestination.allCases.map(\.id)).count == 5)
        #expect(Set(LibraryDestination.allCases.map(\.emptyTitle)).count == 5)
        for destination in LibraryDestination.allCases {
            #expect(!destination.title.isEmpty)
            #expect(!destination.symbol.isEmpty)
            #expect(!destination.emptyMessage.isEmpty)
        }
    }

    @Test func unknownStoredPreferencesRecoverSafely() {
        #expect(LibraryLayout(storedValue: "removed-layout") == .grid)
        #expect(AppAppearance(storedValue: "removed-appearance") == .system)
    }

    @Test func storedPreferencesRoundTrip() {
        for layout in LibraryLayout.allCases {
            #expect(LibraryLayout(storedValue: layout.rawValue) == layout)
        }
        for appearance in AppAppearance.allCases {
            #expect(AppAppearance(storedValue: appearance.rawValue) == appearance)
        }
    }
}

struct LinkNormalizerTests {
    @Test func acceptsWhatPeopleActuallyPaste() {
        #expect(LinkNormalizer.normalize("apple.com")?.absoluteString == "https://apple.com")
        #expect(LinkNormalizer.normalize("  https://example.com/a?b=1 ")?.absoluteString == "https://example.com/a?b=1")
        #expect(LinkNormalizer.normalize("http://sub.example.co.uk/x") != nil)
    }

    @Test func rejectsThingsThatAreNotLinks() {
        for junk in ["", "   ", "just some words", "notadomain", "file:///etc/passwd", "javascript:alert(1)"] {
            #expect(LinkNormalizer.normalize(junk) == nil, "accepted \(junk)")
        }
    }
}

@MainActor
struct LibraryStoreTests {
    private func makeStore() -> LibraryStore {
        let path = NSTemporaryDirectory() + "linkshelf-tests-\(UUID().uuidString)/library.json"
        setenv("LINKSHELF_STORE", path, 1)
        return LibraryStore()
    }

    @Test func savesFoldersAndFilesLinksIntoThem() throws {
        let store = makeStore()
        store.addFolder(named: "Reading")
        let folder = try #require(store.folders.first)
        #expect(store.addLink("swift.org", folderID: folder.id) != nil)
        store.addLink("apple.com")
        #expect(store.links(in: .folder(folder.id)).count == 1)
        #expect(store.links(in: .destination(.all)).count == 2)
        // Survives a relaunch.
        #expect(LibraryStore().links(in: .folder(folder.id)).count == 1)
    }

    @Test func duplicateFoldersAndLinksAreRejected() {
        let store = makeStore()
        store.addFolder(named: "Reading")
        store.addFolder(named: "reading")
        #expect(store.folders.count == 1)
        store.addLink("apple.com")
        store.addLink("https://apple.com")
        #expect(store.links(in: .destination(.all)).count == 1)
        #expect(store.lastError != nil)
        #expect(store.addLink("not a link") == nil)
    }

    @Test func favoritesArchiveAndTrashFilterCorrectly() throws {
        let store = makeStore()
        let keep = try #require(store.addLink("apple.com"))
        let shelve = try #require(store.addLink("swift.org"))
        let bin = try #require(store.addLink("example.com"))
        store.toggleFavorite(keep)
        store.archive(shelve)
        store.trash(bin)
        #expect(store.links(in: .destination(.favorites)).map(\.id) == [keep.id])
        #expect(store.links(in: .destination(.archive)).map(\.id) == [shelve.id])
        #expect(store.links(in: .destination(.trash)).map(\.id) == [bin.id])
        #expect(store.links(in: .destination(.all)).map(\.id) == [keep.id])
        store.deleteForever(bin)
        #expect(store.links(in: .destination(.trash)).isEmpty)
    }
}
