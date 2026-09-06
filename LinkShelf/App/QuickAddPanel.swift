import AppKit
import SwiftUI

/// A small floating box for saving a link without the main window. The widget's
/// + button opens this; a widget has nowhere to type.
@MainActor
enum QuickAdd {
    private static var panel: NSPanel?
    /// Windows hidden to keep the box on its own; restored when it closes.
    private static var hidden: [NSWindow] = []

    static func showNewFolder() {
        let view = QuickAddView(folderName: nil, initialText: "", placeholder: "Folder name",
                                caption: "Return to create · Escape to close") { name in
            let store = LibraryStore()
            store.addFolder(named: name)
            close()
        } onCancel: {
            close()
        }
        present(view, title: "New Folder", height: 118)
    }

    static func show(folderID: UUID?) {
        let library = LibraryFile.load()
        let folder = library.folders.first { $0.id == folderID }
        let clipboard = NSPasteboard.general.string(forType: .string) ?? ""
        let prefill = LinkNormalizer.normalize(clipboard) == nil ? "" : clipboard

        let view = QuickAddView(folderName: folder?.name, initialText: prefill,
                                placeholder: "https://example.com",
                                caption: "Return to save · Escape to close") { text in
            let store = LibraryStore()
            guard store.addLink(text, folderID: folderID) != nil else { return }
            close()
        } onCancel: {
            close()
        }
        present(view, title: "Add Link", height: folder == nil ? 118 : 138)
    }

    private static func present(_ view: some View, title: String, height: CGFloat) {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.title = title
        panel.contentView = NSHostingView(rootView: view)
        panel.setContentSize(NSSize(width: 420, height: height))
        panel.center()
        if let frame = panel.screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: frame.maxY - panel.frame.height - 120))
        }
        // The point of this box is not to open the app, so anything else the
        // app has on screen steps aside until it closes.
        hidden = NSApp.windows.filter { $0.isVisible && $0 !== panel }
        for window in hidden { window.orderOut(nil) }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    static func close() {
        panel?.orderOut(nil)
        guard !hidden.isEmpty else {
            NSApp.hide(nil)
            return
        }
        for window in hidden { window.makeKeyAndOrderFront(nil) }
        hidden = []
    }

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero,
                            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.title = "Add Link"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        return panel
    }

}

private struct QuickAddView: View {
    let folderName: String?
    let placeholder: String
    let caption: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String
    @FocusState private var focused: Bool

    init(folderName: String?, initialText: String, placeholder: String, caption: String,
         onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.folderName = folderName
        self.placeholder = placeholder
        self.caption = caption
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .focused($focused)
                .accessibilityIdentifier("quickAddField")
                .onSubmit { onSave(text) }
            if let folderName {
                Label("Saving to \(folderName)", systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Save") { onSave(text) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AppSpacing.large)
        .onExitCommand(perform: onCancel)
        .onAppear { focused = true }
    }
}
