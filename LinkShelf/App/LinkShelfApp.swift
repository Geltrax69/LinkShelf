import SwiftUI

@main
struct LinkShelfApp: App {
    private let preferences: UserDefaults
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing") {
            let domain = "com.geltrax69.LinkShelf.UITesting"
            let isolated = UserDefaults(suiteName: domain)!
            if arguments.contains("--reset-preferences") {
                isolated.removePersistentDomain(forName: domain)
                try? FileManager.default.removeItem(at: LibraryFile.url)
            }
            if let override = arguments.first(where: { $0.hasPrefix("--appearance=") }) {
                isolated.set(String(override.dropFirst("--appearance=".count)), forKey: "appearance")
            }
            preferences = isolated
        } else {
            preferences = .standard
        }
        _appearance = AppStorage(wrappedValue: AppAppearance.system.rawValue, "appearance", store: preferences)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .defaultAppStorage(preferences)
                .preferredColorScheme(colorScheme)
        }
        .defaultSize(width: AppMetrics.defaultWidth, height: AppMetrics.defaultHeight)
        .commands { LibraryCommands() }

        Settings {
            SettingsView()
                .defaultAppStorage(preferences)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppAppearance(storedValue: appearance) {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
