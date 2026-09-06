# Testing

## First-shell acceptance criteria
- Launches a native macOS window with library sidebar and contextual empty states.
- All Links, Favorites, Recent, Archive and Trash navigate without dead ends.
- Command-1 and Command-2 select All Links and Favorites.
- Grid/list preference survives relaunch; the shell truthfully contains no saved content.
- Settings exposes system/light/dark appearance without overriding macOS globally.
- First build scope is visible in an informational sheet; no nonfunctional add/save controls.
- Empty states are readable at the minimum window size and in both appearances. Search begins in M9.

## Automated checks
Use the shared `LinkShelf` scheme. Swift Testing validates navigation identity and preference fallback behavior. XCTest launches the app in an isolated preferences domain and checks navigation, shortcuts, view preference restoration, build information, and screenshots. No live network or production library fixtures are used.

The exact verified commands/results are recorded in `PROJECT_TRACKER.md`. Test screenshots are attached to the `.xcresult` output. Test success does not establish VoiceOver quality, multi-monitor correctness, or production readiness.

The suite also resizes a real window to approximately 720×532 points (including title bar), asserts sidebar/footer hit-testing, opens Settings with Command-comma and selects Dark appearance. Preferences are isolated; XCTest window restoration can persist geometry between test launches. The shell's root provides a finite height to both native split columns to prevent offscreen layout on macOS 26.

## Links, folders and widgets
Swift Testing covers URL normalization (bare hosts, whitespace, rejected junk and non-web schemes), folder creation with case-insensitive duplicate refusal, duplicate-link refusal, folder filing, favorite/archive/trash/delete filtering, and reload from disk. Store tests point `LINKSHELF_STORE` at a fresh temporary file, so they never touch the real library.

XCTest covers adding a link through the toolbar sheet, creating a folder, moving a link into it via the context menu, and the error shown for input that is not a web address. UI-test runs write to a temporary library that `--reset-preferences` deletes on launch.

The widget extension is verified by hand: `Scripts/install.sh`, then place the widget from the desktop widget gallery and use **Edit Widget** to switch shelves. There is no automated WidgetKit snapshot test; the timeline provider reads the same `LibraryFile` the unit tests exercise.

## Later gates
For M3 onward, write failing domain tests before implementation, add isolated SwiftData integration tests, and automate critical save/edit/move/restore flows. Test URL preservation, cancellation, cache limits and widget snapshots independently of live websites. Add manual keyboard-only, VoiceOver, contrast, reduced-motion, Retina and multiple-display checks before beta.
