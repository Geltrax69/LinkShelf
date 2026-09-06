import AppIntents
import AppKit
import SwiftUI
import WidgetKit

struct LinkEntry: TimelineEntry {
    let date = Date()
    let title: String
    let links: [SavedLink]
    /// Folder the "+" button files into; nil for All Links and Favorites.
    var folderID: String?
    var folder: Folder?
}

struct LinkProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LinkEntry {
        LinkEntry(title: "All Links", links: [])
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
        let folder = configuration.folder ?? .allLinks
        let live = library.links.filter { !$0.trashed && !$0.archived }
        let links: [SavedLink]
        switch folder.id {
        case "all": links = live
        case "favorites": links = live.filter(\.favorite)
        default: links = live.filter { $0.folderID?.uuidString == folder.id }
        }
        let target = ["all", "favorites"].contains(folder.id) ? nil : folder.id
        return LinkEntry(title: folder.name,
                         links: Array(links.sorted { $0.added > $1.added }.prefix(8)),
                         folderID: target,
                         folder: library.folders.first { $0.id.uuidString == folder.id })
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
            HStack(spacing: 4) {
                if let folder = entry.folder, let icon = folder.iconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 13, height: 13)
                        .clipShape(.rect(cornerRadius: 3))
                } else {
                    Image(systemName: entry.folder?.symbol ?? "books.vertical.fill")
                        .font(.system(size: 10))
                }
                Text(entry.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
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
                .help("Paste the copied link into this shelf")
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 6)

            if entry.links.isEmpty {
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
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entry.links.prefix(visibleCount).enumerated()), id: \.element.id) { index, link in
                        if index > 0 { Divider().opacity(0.35) }
                        Button(intent: OpenLinkIntent(address: link.url.absoluteString)) {
                            row(for: link)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
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
