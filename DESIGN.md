---
name: LinkShelf
description: A native macOS visual-link workspace foundation.
---

# Design System: LinkShelf

## Overview

**Creative North Star: "A native visual-link workspace"**

LinkShelf is a native Mac productivity utility for revisiting visual resources alongside a browser. The supplied blueprint fixes the visual direction: system controls, system typography, SF Symbols, semantic colors, and restrained native materials. Preserve its sidebar, contextual main content, and optional future inspector structure.

This record describes the implemented first shell. Compact sidebar rows lead to generous, contextual empty states; toolbar controls expose view preferences and build information. The library contains no invented links. Saving links, library persistence, and widgets remain future work; appearance and view preferences already use native settings storage.

**Key Characteristics:**
- Native Mac navigation and interaction conventions.
- Semantic appearance with legible app-authored text.
- Compact navigation and spacious, contextual empty states.
- System typography and SF Symbols without decorative chrome.

## Colors

The palette follows macOS semantic appearance rather than fixed color literals. System appearance is the default; Settings also supports Light and Dark overrides.

### Primary

- **System accent** (`Color.accentColor`): identifies the selected grid/list toolbar preference; native selection and action controls retain their platform treatments.

### Neutral

- **Primary foreground** (`.primary`): app-authored body, helper, count, and status text, including the empty-state message, folder guidance, footer, build information, and settings explanation.
- **Secondary foreground** (`.secondary`): the decorative empty-state symbol and unselected view-preference symbols. Native sidebar headings and icon styles remain system-managed.
- **System background** (`.background`): the detail surface; the sidebar and native presentations retain their platform surfaces.

**The Semantic Contrast Rule.** Use `.primary` for app-authored body, helper, count, and status text. Keep `.secondary` for the existing subordinate symbols and let native controls manage their own labels, headings, and selection treatments. Verify both system appearances when adding a surface.

Native semantic roles are recorded here without invented CSS color values or synthetic tonal ramps. SwiftUI remains their normative implementation source.

## Typography

The system font and semantic text styles provide the hierarchy. There is no custom display face or separate body family.

- **Destination title:** `.largeTitle.weight(.semibold)`.
- **Empty-state and sheet title:** `.title2.weight(.semibold)`.
- **Sheet subsection title:** `.title3.weight(.semibold)`.
- **Explanatory content:** `.body`, or the platform default body role.
- **Counts and supporting settings/build copy:** `.callout`.
- **Folder guidance and footer:** `.caption`.

The empty-state message uses the `xSmall` spacing step for additional line spacing. Its decorative SF Symbol uses a light system weight; this icon treatment is not a text-style token. Native navigation and controls retain their standard typography.

**The Native Hierarchy Rule.** Use SwiftUI semantic text styles and native control sizes. Establish emphasis through text role and semibold weight rather than custom display fonts or manually scaled control labels.

## Layout

The operating surface is a native `NavigationSplitView`. The current shell implements sidebar and detail columns; an inspector remains a future extension of the pinned blueprint. A root `GeometryReader` provides finite available height to both columns so their content stays within the visible window.

The default window is 1040 × 700 points, with a minimum of 720 × 480 points, as defined by `AppMetrics`. The sidebar spans 180–280 points with an ideal width of 220. Main content adapts to the remaining width. These are native window constraints, not web breakpoints.

`AppSpacing` defines the shared rhythm in points: `xSmall` (4), `small` (8), `medium` (12), `large` (16), `xLarge` (24), and `xxLarge` (32). Reuse these names rather than introducing a parallel scale.

The detail column places its destination title and count above a centered empty state, with a footer anchored beneath it. The header uses `xxLarge` padding; the footer uses `xLarge` horizontal and `medium` vertical padding. Flexible space around the empty state has a `large` minimum. The empty-state content is constrained to 350 points with `xLarge` horizontal padding; explanatory text wraps naturally.

## Elevation & Depth

Depth comes from native sidebar, toolbar, sheet, and grouped-form presentation. The app adds no custom shadows, material overlays, or decorative animation. Platform materials may provide translucency and separation without app-authored imitation.

**The Native Depth Rule.** Let macOS supply sidebar, toolbar, sheet, and control depth. Do not add fake glass, decorative elevation, or repeated app-authored shadows.

## Shapes

Standard macOS lists, controls, menu pickers, grouped forms, and sheets own their shapes and corners. The shell defines no custom radius scale, card silhouette, or decorative border system. Use SF Symbols for destination and toolbar imagery.

## Components

### Navigation

A native sidebar `List(selection:)` presents All Links, Favorites, and Recent under Library, a Folders section with truthful empty guidance, and Archive and Trash destinations. Rows use labeled SF Symbols and native selection. Selecting a destination updates the detail title, symbol, and explanatory copy together.

### Contextual empty state

A centered vertical stack pairs a decorative, accessibility-hidden SF Symbol with a semibold title and wrapping explanatory text. Maintain the shared hierarchy and spacing across destinations; tailor the copy to the selected destination. This first viewport remains an empty library.

### Toolbar and footer

Grid and list preference buttons use SF Symbols, accessibility labels, help text, and a selected accessibility trait. The active choice uses the accent, and the footer reflects the chosen view with the current zero-link count. The information button and the footer’s native link-style “About this build” button open the same sheet. View preferences do not imply an implemented link collection.

### Build-information sheet

The sheet uses native presentation, `xxLarge` padding, semantic headings, plain progress labels, and an explicit statement that saving links is unavailable. Its Done button is the default keyboard action. Build-stage detail belongs here instead of filling the primary library surface.

### Settings

A native grouped `Form` contains menu pickers for Appearance and Library view, followed by legible explanatory copy. It uses `large` padding and native control interaction. Settings share the main window’s appearance preference.

## Do's and Don'ts

### Do:

- Do preserve the blueprint’s native split-view structure and contextual destination changes.
- Do use AppSpacing and AppMetrics for their existing roles; all native dimensions are in points.
- Do keep important controls labeled for accessibility and provide help text for toolbar symbols.
- Do keep text legible in light and dark appearances, including the smallest helper and footer copy.
- Do let native controls supply keyboard, focus, hover, and selection behavior.
- Do expose development-stage limitations through the build-information sheet.

### Don't:

- Don’t introduce a custom title bar, web dashboard chrome, or fake glass.
- Don’t add decorative animation or repeated shadows.
- Don’t populate the first shell with fabricated link cards or imply that saving, library persistence, or widgets already work.
- Don’t expose add or edit actions before their behavior exists.
- Don’t convert native semantic colors or type styles into fixed web approximations.
