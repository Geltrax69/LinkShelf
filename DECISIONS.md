# Architecture Decisions

## ADR-001 — Native macOS, incremental delivery
Accepted. Follow the supplied blueprint: SwiftUI, macOS 14 minimum, focused AppKit bridges, SwiftData for later persistence. The first session ends at a buildable, tested shell. Do not seed fake saved links or present unimplemented features as working.

## ADR-002 — Reproducible Xcode project
Accepted. Use installed XcodeGen to generate the checked-in `LinkShelf.xcodeproj` from `project.yml`. It is a development tool, not an app dependency. Swift Testing covers deterministic rules; XCTest covers actual UI navigation. No third-party runtime libraries.

## ADR-003 — Defer widget implementation until persistence
Accepted. Create the widget extension in M10. The blueprint's ordered implementation explicitly says not to start widgets before persistence is stable. Share narrow presentation snapshots through an App Group rather than granting the widget responsibility for metadata networking.

## ADR-004 — Work in the user's existing directory
Accepted. Keep the project in `Mac_Widgets`. The installed `~/bin/repo` script always switches to `~/PROJECTS/<name>` and pushes; invoking `repo linkshelf-macos` would operate on another directory. Use reviewed, conventional local Git commits here. Remote creation/publication is not needed for the requested first app build. Do not modify the user's global Git identity.

## ADR-005 — Entitlements follow implemented effects
Accepted. Enable App Sandbox in the app target. The shell needs no network, file-import, or App Group entitlement. Add and document those only alongside metadata, icon import, and widget milestones. Use local ad-hoc signing (`CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual`) for build/tests without a development team. An unsigned build compiled and passed unit tests, but its UI runner was killed before connecting on this Mac. Release signing is a later step.
