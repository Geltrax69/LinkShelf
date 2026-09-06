import SwiftUI
import AppKit

struct RootView: View {
    @State private var store = LibraryStore()
    @State private var selection: LibrarySection? = .destination(.all)
    @State private var showingBuildInformation = false
    @State private var showingNewFolder = false
    @State private var pastedText = ""
    @State private var showingAddLink = false
    @AppStorage("libraryLayout") private var layoutValue = LibraryLayout.grid.rawValue

    private var section: LibrarySection { selection ?? .destination(.all) }
    private var layout: LibraryLayout { LibraryLayout(storedValue: layoutValue) }
    private var links: [SavedLink] { store.links(in: section) }

    private var title: String {
        switch section {
        case .destination(let destination): destination.title
        case .folder(let id): store.folders.first { $0.id == id }?.name ?? "Folder"
        }
    }

    private var currentFolderID: UUID? {
        if case .folder(let id) = section { return id }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            librarySplitView(height: geometry.size.height)
        }
        .frame(minWidth: AppMetrics.minimumWidth, maxWidth: .infinity,
               minHeight: AppMetrics.minimumHeight, maxHeight: .infinity)
        .focusedSceneValue(\.librarySelection, $selection)
        .focusedSceneValue(\.libraryAddLink) {
            pastedText = ""
            showingAddLink = true
        }
        .sheet(isPresented: $showingBuildInformation) { BuildInformationView() }
        .sheet(isPresented: $showingNewFolder) {
            NameSheet(title: "New Folder", placeholder: "Folder name", confirm: "Create",
                      fieldIdentifier: "folderNameField", initialText: "") { name in
                store.addFolder(named: name)
                showingNewFolder = false
            }
        }
        .sheet(isPresented: $showingAddLink) {
            NameSheet(title: "Add Link", placeholder: "https://example.com", confirm: "Save",
                      fieldIdentifier: "linkField", initialText: pastedText,
                      footnote: currentFolderID == nil ? nil : "Saved to “\(title)”.") { text in
                if store.addLink(text, folderID: currentFolderID) != nil { showingAddLink = false }
            }
        }
    }

    // MARK: - Layout

    private func librarySplitView(height: CGFloat) -> some View {
        NavigationSplitView {
            sidebar
                .frame(height: height)
                .navigationTitle("LinkShelf")
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            detail
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(.background)
                .navigationTitle(title)
                .toolbar { toolbar }
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Library") {
                destinationRow(.all)
                destinationRow(.favorites)
                destinationRow(.recent)
            }
            Section("Folders") {
                if store.folders.isEmpty {
                    Text("Your folders will appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, AppSpacing.xSmall)
                }
                ForEach(store.folders) { folder in
                    Label {
                        Text(folder.name)
                    } icon: {
                        FolderIcon(folder: folder, size: 16)
                    }
                    .badge(store.links(in: .folder(folder.id)).count)
                    .accessibilityIdentifier("folder.\(folder.name)")
                    .tag(LibrarySection.folder(folder.id))
                    .contextMenu {
                        Button("Choose Icon Image…") { chooseIcon(for: folder) }
                        Menu("Use a Symbol") {
                            ForEach(Folder.symbolChoices, id: \.self) { symbol in
                                Button {
                                    store.setSymbol(symbol, for: folder)
                                } label: {
                                    Label(symbol, systemImage: symbol)
                                }
                            }
                        }
                        Divider()
                        Button("Delete Folder", role: .destructive) { store.deleteFolder(folder) }
                    }
                }
                Button {
                    showingNewFolder = true
                } label: {
                    Label("New Folder", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("newFolder")
            }
            Section {
                destinationRow(.archive)
                destinationRow(.trash)
            }
        }
        .listStyle(.sidebar)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.largeTitle.weight(.semibold))
                Spacer()
                Text(countLabel).font(.callout).foregroundStyle(.secondary)
            }
            .padding(AppSpacing.xxLarge)
            .padding(.bottom, -AppSpacing.medium)

            if links.isEmpty {
                Spacer(minLength: AppSpacing.large)
                emptyState
                Spacer(minLength: AppSpacing.large)
            } else if layout == .grid {
                ScrollView { grid }
            } else {
                ScrollView { rows }
            }

            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, AppSpacing.xLarge)
                    .accessibilityIdentifier("libraryError")
            }

            HStack {
                Text("\(layout.title) · \(countLabel)")
                Spacer()
                Button("About this build") { showingBuildInformation = true }
                    .buttonStyle(.link)
                    .accessibilityIdentifier("buildInformationFooter")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.vertical, AppSpacing.medium)
        }
        // A real paste gesture hands over the providers; the sandbox does not
        // allow reading NSPasteboard behind the user's back.
        .onPasteCommand(of: [.url, .plainText]) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    guard let text = object as? String else { return }
                    Task { @MainActor in store.addLink(text, folderID: currentFolderID) }
                }
            }
        }
    }

    private var countLabel: String { links.count == 1 ? "1 link" : "\(links.count) links" }

    @ViewBuilder private var emptyState: some View {
        switch section {
        case .destination(let destination): LibraryEmptyView(destination: destination)
        case .folder: LibraryEmptyView(destination: .all)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpacing.large)], spacing: AppSpacing.large) {
            ForEach(links) { link in LinkCard(link: link) .modifier(LinkActions(store: store, link: link)) }
        }
        .padding(AppSpacing.xLarge)
    }

    private var rows: some View {
        LazyVStack(spacing: 0) {
            ForEach(links) { link in
                LinkRow(link: link)
                    .modifier(LinkActions(store: store, link: link))
                Divider()
            }
        }
        .padding(.horizontal, AppSpacing.xLarge)
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                let clipboard = NSPasteboard.general.string(forType: .string) ?? ""
                pastedText = LinkNormalizer.normalize(clipboard) == nil ? "" : clipboard
                showingAddLink = true
            } label: {
                Label("Add Link", systemImage: "plus")
            }
            .help("Add a link (⌘N, or ⌘V anywhere in the library)")
            .accessibilityIdentifier("addLink")
        }
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: AppSpacing.xSmall) {
                ForEach(LibraryLayout.allCases) { option in
                    Button {
                        layoutValue = option.rawValue
                    } label: {
                        Image(systemName: option.symbol)
                            .foregroundStyle(layout == option ? Color.accentColor : .secondary)
                    }
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(layout == option ? .isSelected : [])
                    .help(option.title)
                }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingBuildInformation = true
            } label: {
                Label("About this build", systemImage: "info.circle")
            }
            .help("About this build")
            .accessibilityIdentifier("buildInformation")
        }
    }

    // MARK: - Sheets and actions

    private func chooseIcon(for folder: Folder) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.prompt = "Use Icon"
        panel.message = "Pick an image for “\(folder.name)”."
        guard panel.runModal() == .OK, let file = panel.url else { return }
        store.setIcon(from: file, for: folder)
    }

    private func destinationRow(_ item: LibraryDestination) -> some View {
        Label(item.title, systemImage: item.symbol)
            .badge(store.links(in: .destination(item)).count)
            .accessibilityIdentifier("destination.\(item.rawValue)")
            .tag(LibrarySection.destination(item))
    }
}

/// Shared open/favorite/move/delete behaviour for cards and rows.
private struct LinkActions: ViewModifier {
    let store: LibraryStore
    let link: SavedLink

    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            .onTapGesture(count: 2) { NSWorkspace.shared.open(link.url) }
            .contextMenu {
                Button("Open in Browser") { NSWorkspace.shared.open(link.url) }
                Button("Copy Link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
                }
                Divider()
                Button(link.favorite ? "Remove from Favorites" : "Add to Favorites") { store.toggleFavorite(link) }
                Menu("Move to Folder") {
                    Button("None") { store.move(link, to: nil) }
                    ForEach(store.folders) { folder in
                        Button(folder.name) { store.move(link, to: folder.id) }
                    }
                }
                Divider()
                if link.trashed {
                    Button("Put Back") { store.restore(link) }
                    Button("Delete Forever", role: .destructive) { store.deleteForever(link) }
                } else {
                    Button("Archive") { store.archive(link) }
                    Button("Move to Trash", role: .destructive) { store.trash(link) }
                }
            }
    }
}

struct LinkCard: View {
    let link: SavedLink

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Thumbnail(link: link, height: 110)
                    .frame(maxWidth: .infinity)
            }
            Text(link.title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: AppSpacing.xSmall) {
                Text(link.host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if link.favorite { Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(AppSpacing.large)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 12))
        .accessibilityIdentifier("link.\(link.host)")
        .accessibilityElement(children: .combine)
    }
}

struct LinkRow: View {
    let link: SavedLink

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Thumbnail(link: link, height: 34)
                .frame(width: 60)
            if link.favorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title).lineLimit(1)
                Text(link.host).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(link.added, style: .date).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.medium)
        .accessibilityIdentifier("link.\(link.host)")
        .accessibilityElement(children: .combine)
    }
}

/// A folder's chosen image, or its symbol.
struct FolderIcon: View {
    let folder: Folder
    var size: CGFloat = 16

    var body: some View {
        if let image = folder.iconImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: size * 0.25))
        } else {
            Image(systemName: folder.symbol)
        }
    }
}

/// Cached preview image, or a neutral placeholder while none exists.
struct Thumbnail: View {
    let link: SavedLink
    let height: CGFloat

    var body: some View {
        Group {
            if let image = link.thumbnailImage {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "globe")
                    .font(.system(size: height / 3))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: height)
        .clipped()
        .background(.quaternary.opacity(0.5))
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}

/// One-field sheet. Its own @State keeps the confirm button in step with what
/// is typed; a parent @State read at presentation time can arrive stale.
struct NameSheet: View {
    let title: String
    let placeholder: String
    let confirm: String
    let fieldIdentifier: String
    var footnote: String?
    let action: (String) -> Void

    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(title: String, placeholder: String, confirm: String, fieldIdentifier: String,
         initialText: String, footnote: String? = nil, action: @escaping (String) -> Void) {
        self.title = title
        self.placeholder = placeholder
        self.confirm = confirm
        self.fieldIdentifier = fieldIdentifier
        self.footnote = footnote
        self.action = action
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text(title).font(.title3.weight(.semibold))
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(fieldIdentifier)
                .onSubmit(submit)
            if let footnote {
                Text(footnote).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(confirm, action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AppSpacing.xxLarge)
        .frame(width: 420)
    }

    private func submit() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        action(text)
    }
}

#Preview("Library") { RootView() }
