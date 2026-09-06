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
        if entry.showingFolders {
            switch family {
            case .systemSmall: 3
            case .systemMedium: 4
            default: 6
            }
        } else {
            switch family {
            case .systemSmall: 3
            case .systemMedium: 3
            default: 5
            }
        }
    }

    private var compact: Bool { family == .systemSmall }
    private var thumbnailWidth: CGFloat { compact ? 34 : 62 }
    private var folderIconSize: CGFloat { compact ? 26 : 34 }

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
        HStack(spacing: 7) {
            chip(entry.canGoBack ? "chevron.backward" : "folder",
                 intent: BrowseIntent(target: entry.canGoBack && entry.showingFolders ? nil : "folders"))

            if !entry.showingFolders, let folder = entry.folder {
                icon(for: folder, size: 18, radius: 4)
            }

            Text(entry.title)
                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            if entry.showingFolders {
                chip("folder.badge.plus", intent: NewFolderIntent())
            } else {
                if !compact, entry.links.count > visibleCount {
                    Text("+\(entry.links.count - visibleCount)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                chip("plus", intent: AddPastedLinkIntent(folderID: entry.folderID))
            }
        }
        .padding(.bottom, 8)
    }

    private func chip(_ symbol: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(.quaternary.opacity(0.5), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func icon(for folder: Folder, size: CGFloat, radius: CGFloat) -> some View {
        if let image = folder.iconImage {
            Image(nsImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: radius))
        } else {
            RoundedRectangle(cornerRadius: radius)
                .fill(.quaternary.opacity(0.6))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: folder.symbol)
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.secondary)
                )
        }
    }

    // MARK: - Lists

    private var linkList: some View {
        VStack(spacing: 5) {
            ForEach(entry.links.prefix(visibleCount)) { link in
                Button(intent: OpenLinkIntent(address: link.url.absoluteString)) {
                    row(for: link)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var folderList: some View {
        VStack(spacing: 5) {
            if entry.folderRows.isEmpty {
                Spacer()
                Text("No folders yet").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            ForEach(entry.folderRows.prefix(visibleCount), id: \.folder.id) { row in
                Button(intent: BrowseIntent(target: row.folder.id.uuidString)) {
                    HStack(spacing: 9) {
                        icon(for: row.folder, size: folderIconSize, radius: folderIconSize * 0.26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.folder.name)
                                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(row.count == 1 ? "1 link" : "\(row.count) links")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
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
        HStack(spacing: 9) {
            thumbnail(for: link)
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.system(size: compact ? 11 : 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text(link.host)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if link.favorite {
                        Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
        .contentShape(.rect)
    }

    @ViewBuilder private func thumbnail(for link: SavedLink) -> some View {
        let height = thumbnailWidth * 0.64
        if let image = link.thumbnailImage {
            Image(nsImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFill()
                .frame(width: thumbnailWidth, height: height)
                .clipShape(.rect(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.6))
                .frame(width: thumbnailWidth, height: height)
                .overlay(
                    Text(link.host.prefix(1).uppercased())
                        .font(.system(size: 13, weight: .semibold))
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
