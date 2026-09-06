# Changelog

## Unreleased
- Added the original LinkShelf specification, project tracker, architecture decisions, and development guidance.
- Added the native macOS app shell with five library destinations and contextual empty states.
- Added persistent grid/list and appearance preferences, standard Settings, and library navigation shortcuts.
- Added app, unit-test, and UI-test Xcode targets plus a macOS CI workflow.
- Verified local ad-hoc signing and bounded column sizing for macOS window layouts.
- Added saved links: paste or type a URL, schemeless input is normalized, duplicates are refused.
- Added user folders with badge counts, per-link move, favorite, archive, trash, restore and delete.
- Added grid cards and list rows with double-click to open, context-menu actions and best-effort page titles.
- Added a WidgetKit extension with small/medium/large families and a per-widget shelf picker (All Links, Favorites, or any folder).
- Library is stored as one JSON file in Application Support, read by both the app and the widget; saving reloads widget timelines.
- Widget thumbnails are downsampled to 480px on save; WidgetKit renders full-size images blank.
- Widget rows open the site in the browser, and a "+" button saves the copied link into that widget's shelf.
- Added a "New LinkShelf Folder" App Intent so folders can be made from Shortcuts or Spotlight without the window.
- Add Link no longer reads the clipboard silently — the sandbox blocks that; ⌘V in the library pastes a link directly.
