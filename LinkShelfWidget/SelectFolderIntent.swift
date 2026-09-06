import AppIntents

struct FolderEntity: AppEntity {
    let id: String
    let name: String

    static let allLinks = FolderEntity(id: "all", name: "All Links")
    static let favorites = FolderEntity(id: "favorites", name: "Favorites")

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Shelf" }
    static let defaultQuery = FolderQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct FolderQuery: EntityQuery {
    private var everything: [FolderEntity] {
        [.allLinks, .favorites] + LibraryFile.load().folders.map { FolderEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func entities(for identifiers: [String]) async throws -> [FolderEntity] {
        everything.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FolderEntity] { everything }
    func defaultResult() -> FolderEntity? { .allLinks }
}

struct SelectFolderIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose Shelf" }
    static var description: IntentDescription { "Pick which links this widget shows." }

    @Parameter(title: "Shelf")
    var folder: FolderEntity?
}
