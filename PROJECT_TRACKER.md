# LinkShelf Project Tracker

## Current Milestone
M2 — Saved links, folders and a working desktop widget.

## Completed
- [x] Read the product blueprint and inspect the empty project directory.
- [x] Verify Xcode 26.3, Swift 6.2.4, and XcodeGen availability.
- [x] Create engineering documentation and milestone checklist.
- [x] Commit documentation: `4401378 docs: define linkshelf architecture and delivery plan`.
- [x] Generate a checked-in Xcode project with app, Swift Testing and XCTest UI targets.
- [x] Implement native sidebar navigation: All Links, Favorites, Recent, Archive and Trash.
- [x] Add contextual empty states, system toolbar, grid/list preference and build information.
- [x] Add system/light/dark appearance settings and Command-1/Command-2 navigation.
- [x] Pass unit tests, navigation, preference relaunch, appearance and compact-window UI checks.
- [x] Pass targeted Settings test after adding a stable accessibility identity to the picker.
- [x] Add a CI workflow using the verified shared scheme and local ad-hoc signing.

- [x] Add saved links with URL normalization and duplicate refusal.
- [x] Add folders, move/favorite/archive/trash/restore/delete actions.
- [x] Fetch page titles and preview images (YouTube stills via oEmbed, others via og:image).
- [x] Add a WidgetKit extension with an App Group store and a per-widget shelf picker.
- [x] Verify end to end in the installed app: saved https://leetcode.com/ and a YouTube watch URL, both with titles and thumbnails, filed into a "Coding" folder, one favorited.

## In Progress
- [ ] Place the widget on the desktop. The macOS desktop widget layer is owned by Notification Centre, which the automation grant cannot cover, so the final drag is a manual step: right-click the desktop ▸ Edit Widgets ▸ LinkShelf.

## Next
- [ ] M7: Cancellable hover previews.
- [ ] M8: Drag and drop between folders, sorting.
- [ ] M9: Deterministic search.
- [ ] M11: Menu bar and keyboard productivity.
- [ ] M12: Accessibility, performance and error handling.
- [ ] M13: Full regression and UI tests.
- [ ] M14: Beta packaging and release documentation.

## Blockers
The widget extension only registers with pluginkit when the app is signed with a real identity (ad-hoc is rejected) and installed in /Applications. `Scripts/install.sh` does both, signing with team D676SQ267J and the App Group `D676SQ267J.group.com.geltrax69.LinkShelf`. Another machine needs its own team ID in `project.yml`, both entitlements files, and `LibraryFile.appGroup`.

## Known Bugs
Fixed: the Add Link sheet read the parent view's state at presentation time, so its Save button stayed disabled and nothing saved. Sheets now own their text state (`NameSheet`).
Fixed: a byte-count prefix could split a UTF-8 sequence and abandon the whole metadata parse; it now falls back to latin1.
Open: search, drag and drop, and hover previews are still unimplemented. Reading the clipboard for the Add Link pre-fill returned nothing under the sandbox in one run; typing or ⇧⌘V both work.

The default 1040×700 window and compact 721×533 window were exercised. VoiceOver, increased contrast, multiple displays and macOS 14 runtime testing remain unverified.

## Test Status
Toolchain and build: PASS (Xcode 26.3, Swift 6.2.4, macOS 26.2 SDK, arm64 host).

- Initial red check: expected missing application module before implementation.
- Swift Testing: 3 tests PASS (destinations, invalid preference fallback, stored preference round trip).
- XCTest: all 5 scenarios have passed in full/targeted runs; final combined run pending.
- Integration: not applicable yet; no database or networking is implemented in M1.
- CI workflow: checked in, not run on GitHub because no remote was published.
- Mechanical UI detector: no findings; native screenshot QA is the relevant visual check.

Latest full regression command:
```sh
xcodebuild -project LinkShelf.xcodeproj -scheme LinkShelf \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/SignedDerivedData \
  -resultBundlePath build/LinkShelf-regression.xcresult \
  test CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
```

Environment findings: an unsigned UI runner was killed before bootstrapping; ad-hoc signing fixed it. A retry against the original unsigned output encountered a linker permission error; a fresh signed DerivedData directory resolved that. No Swift compiler warnings. Xcode's App Intents extractor emits “Metadata extraction skipped. No AppIntents.framework dependency found.” because this shell intentionally has no intents. The system also logs `linkd.autoShortcut` connection noise during hosted unit tests; it does not fail tests.

Regression found and fixed: unconstrained native split columns overflowed the window on macOS 26. Columns now receive a finite height from root geometry. Tests assert sidebar and footer hit-testing and resize the actual window. Settings pickers have explicit accessibility labels/identifiers.

## Important Files
- `LinkShelf_macOS_Project_Blueprint.md` — original requirements, preserved.
- `project.yml` and `LinkShelf.xcodeproj` — reproducible targets and shared scheme.
- `LinkShelf/App/RootView.swift` — window, sidebar and toolbar.
- `LinkShelf/App/LinkShelfApp.swift` — scenes and isolated test preferences.
- `LinkShelf/Features/Library/LibraryDestination.swift` — pure navigation/preference values.
- `LinkShelf/Features/Library/LibraryEmptyView.swift` — empty states and first-build information.
- `LinkShelf/Features/Settings/SettingsView.swift` — appearance and layout preferences.
- `LinkShelfTests` and `LinkShelfUITests` — deterministic and actual app tests.
- `Docs/architecture.md` and `Docs/testing.md` — engineering boundaries and verification.

## Last Commit
`4401378 docs: define linkshelf architecture and delivery plan`. The scaffold commit will include this updated tracker; `git log -1` is authoritative for its final hash.

## Next Recommended Commit
`feat: add swiftdata folder persistence and validation`
