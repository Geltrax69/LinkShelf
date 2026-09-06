import AppKit
import SwiftUI

/// Bridges the widget's + button to the floating quick-add box, and keeps the
/// main window out of the way when the app was launched only for that box.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchedAt = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(forName: AddLinkRequest.didPost, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                // ponytail: a launch this recent can only be the widget's doing.
                if Date().timeIntervalSince(self.launchedAt) < 5 {
                    for window in NSApp.windows where window.isVisible { window.close() }
                }
                QuickAdd.show(folderID: AddLinkRequest.folderID)
            }
        }
    }
}

@main
struct LinkShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
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
