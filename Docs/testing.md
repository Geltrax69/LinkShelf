# Testing

## First-shell acceptance criteria
- Launches a native macOS window with library sidebar and contextual empty states.
- All Links, Favorites, Recent, Archive and Trash navigate without dead ends.
- Command-1 and Command-2 select All Links and Favorites.
- Grid/list preference survives relaunch; the shell truthfully contains no saved content.
- Settings exposes system/light/dark appearance without overriding macOS globally.
- First build scope is visible in an informational sheet; no nonfunctional add/save controls.
- Empty and search states are readable at the minimum window size and in both appearances.

## Automated checks
Use the shared `LinkShelf` scheme. Swift Testing validates navigation identity and preference fallback behavior. XCTest launches the app in an isolated preferences domain and checks navigation, shortcuts, view preference restoration, build information, and screenshots. No live network or production library fixtures are used.

The exact verified commands/results are recorded in `PROJECT_TRACKER.md`. Test screenshots are attached to the `.xcresult` output. Test success does not establish VoiceOver quality, multi-monitor correctness, or production readiness.

## Later gates
For M3 onward, write failing domain tests before implementation, add isolated SwiftData integration tests, and automate critical save/edit/move/restore flows. Test URL preservation, cancellation, cache limits and widget snapshots independently of live websites. Add manual keyboard-only, VoiceOver, contrast, reduced-motion, Retina and multiple-display checks before beta.
