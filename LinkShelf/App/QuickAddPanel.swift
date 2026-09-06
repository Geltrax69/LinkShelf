import AppKit
import SwiftUI

/// A small floating box for saving a link without the main window. The widget's
/// + button opens this; a widget has nowhere to type.
@MainActor
enum QuickAdd {
    private static var panel: NSPanel?

    static func show(folderID: UUID?) {
        let library = LibraryFile.load()
        let folder = library.folders.first { $0.id == folderID }
        let clipboard = NSPasteboard.general.string(forType: .string) ?? ""
        let prefill = LinkNormalizer.normalize(clipboard) == nil ? "" : clipboard

        let view = QuickAddView(folderName: folder?.name, initialText: prefill) { text in
            save(text, folderID: folderID)
        } onCancel: {
            close()
        }

        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: view)
        panel.setContentSize(NSSize(width: 420, height: folder == nil ? 118 : 138))
        panel.center()
        if let frame = panel.screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: frame.maxY - panel.frame.height - 120))
        }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    static func close() {
        panel?.orderOut(nil)
        // Launched only to show this box? Then there is nothing left to show.
        if NSApp.windows.allSatisfy({ !$0.isVisible || $0 === panel }) { NSApp.hide(nil) }
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

    private static func save(_ text: String, folderID: UUID?) {
        let store = LibraryStore()
        guard store.addLink(text, folderID: folderID) != nil else { return }
        close()
    }
}

private struct QuickAddView: View {
    let folderName: String?
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String
    @FocusState private var focused: Bool

    init(folderName: String?, initialText: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.folderName = folderName
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            TextField("https://example.com", text: $text)
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
                Text("Return to save · Escape to close")
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
