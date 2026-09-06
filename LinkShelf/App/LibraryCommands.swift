import SwiftUI

private struct LibrarySelectionKey: FocusedValueKey {
    typealias Value = Binding<LibrarySection?>
}

private struct LibraryAddLinkKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var librarySelection: Binding<LibrarySection?>? {
        get { self[LibrarySelectionKey.self] }
        set { self[LibrarySelectionKey.self] = newValue }
    }

    var libraryAddLink: (() -> Void)? {
        get { self[LibraryAddLinkKey.self] }
        set { self[LibraryAddLinkKey.self] = newValue }
    }
}

struct LibraryCommands: Commands {
    @FocusedValue(\.librarySelection) private var selection
    @FocusedValue(\.libraryAddLink) private var addLink

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add Link…") { addLink?() }
                .keyboardShortcut("n")
                .disabled(addLink == nil)
        }
        CommandMenu("Library") {
            Button("All Links") { selection?.wrappedValue = .destination(.all) }
                .keyboardShortcut("1")
                .disabled(selection == nil)
            Button("Favorites") { selection?.wrappedValue = .destination(.favorites) }
                .keyboardShortcut("2")
                .disabled(selection == nil)
        }
    }
}
