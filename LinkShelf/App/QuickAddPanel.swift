import AppKit
import SwiftUI

/// A small floating box for saving a link without the main window. The widget's
/// + button opens this; a widget has nowhere to type.
@MainActor
enum QuickAdd {
    private static var panel: NSPanel?
    /// Windows hidden to keep the box on its own; restored when it closes.
    private static var hidden: [NSWindow] = []
    /// The app's own window is created after the intent runs, so hiding once
    /// is not enough — watch for latecomers while the box is up.
    private static var watcher: Any?

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

    /// Whether the app already had a window on screen when the box opened.
    private static var wasOpenBefore = false

    private static func present(_ view: some View, title: String, height: CGFloat) {
        wasOpenBefore = NSApp.windows.contains { $0.isVisible && !($0 is NSPanel) }
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
        if watcher == nil {
            watcher = NotificationCenter.default.addObserver(
                forName: NSWindow.didUpdateNotification, object: nil, queue: .main
            ) { notification in
                let window = notification.object as? NSWindow
                MainActor.assumeIsolated { Self.hideLatecomer(window) }
            }
        }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    private static func hideLatecomer(_ window: NSWindow?) {
        guard let window, window !== panel, window.isVisible, !(window is NSPanel) else { return }
        hidden.append(window)
        window.orderOut(nil)
    }

    static func close() {
        if let watcher {
            NotificationCenter.default.removeObserver(watcher)
            self.watcher = nil
        }
        panel?.orderOut(nil)
        // Nothing was on screen before, so leave nothing behind.
        let restore = hidden.filter { $0.isReleasedWhenClosed == false || $0.isVisible }
        hidden = []
        guard !restore.isEmpty, wasOpenBefore else {
            NSApp.hide(nil)
            return
        }
        for window in restore { window.makeKeyAndOrderFront(nil) }
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
