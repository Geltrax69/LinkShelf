# LinkShelf

A native macOS workspace for saved links, with visual folders, previews, and desktop widgets planned in incremental milestones.

Requires macOS 14+, Xcode 16+ (Swift Testing), and XcodeGen only when regenerating the project. Developed with Xcode 26.3 / Swift 6.2.4.

## Development

Open `LinkShelf.xcodeproj`, select the **LinkShelf** scheme, and run on **My Mac**. The checked-in project needs no third-party runtime dependencies.

```sh
xcodegen generate
xcodebuild -project LinkShelf.xcodeproj -scheme LinkShelf -destination 'platform=macOS' -derivedDataPath build/DerivedData build CODE_SIGNING_ALLOWED=NO
xcodebuild -project LinkShelf.xcodeproj -scheme LinkShelf -destination 'platform=macOS' -derivedDataPath build/DerivedData test CODE_SIGNING_ALLOWED=NO
```

The first build is a navigation shell; saving links, persistence, previews, and widgets are subsequent milestones. See [PROJECT_TRACKER.md](PROJECT_TRACKER.md) for verified progress and [the blueprint](LinkShelf_macOS_Project_Blueprint.md) for the complete specification.

Before every coding session, read the tracker and decisions, inspect Git status and recent commits, and run the relevant health check.
