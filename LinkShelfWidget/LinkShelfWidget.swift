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

    private var metrics: Metrics { Metrics(family: family) }
    private var compact: Bool { family == .systemSmall }
    private var visibleCount: Int { entry.showingFolders ? metrics.folderRows : metrics.linkRows }

    /// One place to size everything, because a 155pt square and a 345pt tall
    /// panel need genuinely different numbers, not the same ones scaled.
    struct Metrics {
        let family: WidgetFamily

        var small: Bool { family == .systemSmall }
        var large: Bool { family == .systemLarge || family == .systemExtraLarge }

        var folderRows: Int { small ? 2 : (large ? 6 : 3) }
        var linkRows: Int { small ? 2 : (large ? 5 : 3) }

        var folderIcon: CGFloat { small ? 24 : (large ? 34 : 30) }
        var thumbnail: CGFloat { small ? 40 : (large ? 68 : 58) }

        var headerTitle: CGFloat { small ? 12 : 14 }
        var headerIcon: CGFloat { small ? 15 : 18 }
        var chip: CGFloat { small ? 17 : 20 }

        var title: CGFloat { small ? 11 : (large ? 13 : 12) }
        var caption: CGFloat { small ? 9 : 10 }
        var titleLines: Int { small ? 2 : (large ? 2 : 1) }

        var rowSpacing: CGFloat { small ? 4 : 5 }
        var rowPadding: CGFloat { small ? 5 : 7 }
        var rowInset: CGFloat { small ? 6 : 8 }
        var corner: CGFloat { small ? 8 : 10 }
        var headerGap: CGFloat { small ? 6 : 8 }
    }

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
        // Clear lets the system's own widget material through, which is what
        // makes Apple's widgets sit on the wallpaper rather than over it.
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: compact ? 5 : 7) {
            chip(entry.canGoBack ? "chevron.backward" : "folder",
                 intent: BrowseIntent(target: entry.canGoBack && entry.showingFolders ? nil : "folders"))

            if !entry.showingFolders, let folder = entry.folder {
                icon(for: folder, size: metrics.headerIcon, radius: metrics.headerIcon * 0.26)
            }

            Text(entry.title)
                .font(.system(size: metrics.headerTitle, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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
        .padding(.bottom, metrics.headerGap)
    }

    private func chip(_ symbol: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: symbol)
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: metrics.chip, height: metrics.chip)
                .background(.quaternary.opacity(0.35), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func icon(for folder: Folder, size: CGFloat, radius: CGFloat) -> some View {
        if let image = folder.iconImage {
            Image(nsImage: image)
                .resizable()
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: radius))
        } else {
            RoundedRectangle(cornerRadius: radius)
                .fill(.quaternary.opacity(0.45))
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
        VStack(spacing: metrics.rowSpacing) {
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
        VStack(spacing: metrics.rowSpacing) {
            if entry.folderRows.isEmpty {
                Spacer()
                Text("No folders yet").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            ForEach(entry.folderRows.prefix(visibleCount), id: \.folder.id) { row in
                Button(intent: BrowseIntent(target: row.folder.id.uuidString)) {
                    HStack(spacing: compact ? 7 : 9) {
                        icon(for: row.folder, size: metrics.folderIcon, radius: metrics.folderIcon * 0.26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.folder.name)
                                .font(.system(size: metrics.title + 1, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(row.count == 1 ? "1 link" : "\(row.count) links")
                                .font(.system(size: metrics.caption))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: compact ? 8 : 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, metrics.rowInset)
                    .padding(.vertical, metrics.rowPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.22), in: .rect(cornerRadius: metrics.corner))
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
                Text("No links yet")
                    .font(.system(size: metrics.title, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(compact ? "Copy a link, press +" : "Copy a web address, then press +")
                    .font(.system(size: metrics.caption))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private func row(for link: SavedLink) -> some View {
        HStack(spacing: compact ? 7 : 9) {
            thumbnail(for: link)
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.system(size: metrics.title + 1, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(metrics.titleLines)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text(link.host)
                        .font(.system(size: metrics.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if link.favorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: metrics.caption - 1))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, metrics.rowInset)
        .padding(.vertical, metrics.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.22), in: .rect(cornerRadius: metrics.corner))
        .contentShape(.rect)
    }

    @ViewBuilder private func thumbnail(for link: SavedLink) -> some View {
        let width = metrics.thumbnail
        let height = width * 0.64
        if let image = link.thumbnailImage {
            Image(nsImage: image)
                .resizable()
                .frame(width: width, height: height)
                .clipShape(.rect(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.45))
                .frame(width: width, height: height)
                .overlay(
                    Text(link.host.prefix(1).uppercased())
                        .font(.system(size: metrics.title + 2, weight: .semibold))
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
