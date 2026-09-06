import AppIntents
import AppKit
import SwiftUI
import WidgetKit

struct LinkEntry: TimelineEntry {
    let date = Date()
    var title: String
    var links: [SavedLink] = []
    /// Non-empty only in the folder browser.
    var folderRows: [(folder: Folder, count: Int)] = []
    var showingFolders = false
    var folder: Folder?
    /// Folder the "+" button files into; nil for All Links and Favorites.
    var folderID: String?
    /// True when the widget has left the shelf it is configured for.
    var canGoBack = false
}

struct LinkProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LinkEntry {
        LinkEntry(title: "All Links")
    }

    func snapshot(for configuration: SelectFolderIntent, in context: Context) async -> LinkEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectFolderIntent, in context: Context) async -> Timeline<LinkEntry> {
        // Reloaded explicitly whenever the app saves; the hourly refresh is
        // only a backstop for edits made while the widget host was asleep.
        Timeline(entries: [entry(for: configuration)], policy: .after(.now.addingTimeInterval(3600)))
    }

    private func entry(for configuration: SelectFolderIntent) -> LinkEntry {
        let library = LibraryFile.load()
        let live = library.links.filter { !$0.trashed && !$0.archived }

        if library.browse == "folders" {
            let rows = library.folders
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                .map { folder in (folder, live.filter { $0.folderID == folder.id }.count) }
            return LinkEntry(title: "Folders", folderRows: rows, showingFolders: true, canGoBack: true)
        }

        if let browsed = library.browse, let folder = library.folders.first(where: { $0.id.uuidString == browsed }) {
            return LinkEntry(title: folder.name,
                             links: sorted(live.filter { $0.folderID == folder.id }),
                             folder: folder,
                             folderID: folder.id.uuidString,
                             canGoBack: true)
        }

        let shelf = configuration.folder ?? .allLinks
        let links: [SavedLink]
        switch shelf.id {
        case "all": links = live
        case "favorites": links = live.filter(\.favorite)
        default: links = live.filter { $0.folderID?.uuidString == shelf.id }
        }
        let folder = library.folders.first { $0.id.uuidString == shelf.id }
        return LinkEntry(title: shelf.name,
                         links: sorted(links),
                         folder: folder,
                         folderID: folder?.id.uuidString)
    }

    private func sorted(_ links: [SavedLink]) -> [SavedLink] {
        Array(links.sorted { $0.added > $1.added }.prefix(8))
    }
}

struct LinkShelfWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LinkEntry

    private var visibleCount: Int {
        switch family {
        case .systemSmall: 3
        case .systemMedium: 4
        default: 7
        }
    }

    private var thumbnailWidth: CGFloat { family == .systemSmall ? 30 : 44 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if entry.showingFolders {
                folderList
            } else if entry.links.isEmpty {
                empty
            } else {
                linkList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 4) {
            if entry.canGoBack {
                Button(intent: BrowseIntent(target: entry.showingFolders ? nil : "folders")) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 14, height: 14)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: BrowseIntent(target: "folders")) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .frame(width: 14, height: 14)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("Browse folders")
            }

            if let icon = entry.folder?.iconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 13, height: 13)
                    .clipShape(.rect(cornerRadius: 3))
            } else if let symbol = entry.folder?.symbol {
                Image(systemName: symbol).font(.system(size: 10))
            }

            Text(entry.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 0)

            if entry.showingFolders {
                Button(intent: NewFolderIntent()) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 16, height: 16)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("New folder")
            } else {
                if entry.links.count > visibleCount {
                    Text("\(entry.links.count)").font(.caption2)
                }
                Button(intent: AddPastedLinkIntent(folderID: entry.folderID)) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 16, height: 16)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("Add a link to this shelf")
            }
        }
        .foregroundStyle(.secondary)
        .padding(.bottom, 6)
    }

    // MARK: - Lists

    private var linkList: some View {
        VStack(spacing: 0) {
            ForEach(Array(entry.links.prefix(visibleCount).enumerated()), id: \.element.id) { index, link in
                if index > 0 { Divider().opacity(0.35) }
                Button(intent: OpenLinkIntent(address: link.url.absoluteString)) {
                    row(for: link)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var folderList: some View {
        VStack(spacing: 0) {
            if entry.folderRows.isEmpty {
                Spacer()
                Text("No folders yet").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            ForEach(Array(entry.folderRows.prefix(visibleCount).enumerated()), id: \.element.folder.id) { index, row in
                if index > 0 { Divider().opacity(0.35) }
                Button(intent: BrowseIntent(target: row.folder.id.uuidString)) {
                    HStack(spacing: 7) {
                        if let icon = row.folder.iconImage {
                            Image(nsImage: icon)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .clipShape(.rect(cornerRadius: 5))
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.quaternary)
                                .frame(width: 22, height: 22)
                                .overlay(Image(systemName: row.folder.symbol).font(.system(size: 11)))
                        }
                        Text(row.folder.name)
                            .font(.system(size: family == .systemSmall ? 11 : 12, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(row.count)").font(.system(size: 10)).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var empty: some View {
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Text("No links yet").font(.caption).foregroundStyle(.secondary)
                Text("Copy a web address, then press +")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private func row(for link: SavedLink) -> some View {
        HStack(spacing: 7) {
            thumbnail(for: link)
            VStack(alignment: .leading, spacing: 1) {
                Text(link.title)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(family == .systemSmall ? 2 : 1)
                    .multilineTextAlignment(.leading)
                if family != .systemSmall {
                    Text(link.host)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if link.favorite {
                Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    @ViewBuilder private func thumbnail(for link: SavedLink) -> some View {
        let height = thumbnailWidth * 0.62
        if let image = link.thumbnailImage {
            Image(nsImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFill()
                .frame(width: thumbnailWidth, height: height)
                .clipShape(.rect(cornerRadius: 4))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: thumbnailWidth, height: height)
                .overlay(
                    Text(link.host.prefix(1).uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                )
        }
    }
}

struct LinkShelfWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LinkShelfWidget", intent: SelectFolderIntent.self, provider: LinkProvider()) { entry in
            LinkShelfWidgetView(entry: entry)
        }
        .configurationDisplayName("LinkShelf")
        .description("Your saved links, one click away.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct LinkShelfWidgetBundle: WidgetBundle {
    var body: some Widget { LinkShelfWidget() }
}
