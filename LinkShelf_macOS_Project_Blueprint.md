# LinkShelf for macOS
## Master Build Prompt + Product Specification + Engineering Plan

> **Working name:** LinkShelf  
> **Platform:** Native macOS  
> **Repository suggestion:** `linkshelf-macos`  
> **Primary goal:** Build a polished native macOS app that turns saved web links and video links into visual, organized, Apple-like workspaces with folders, thumbnails, hover previews, custom icons, search, and configurable desktop widgets.

---

# 1. MASTER BUILD PROMPT

Copy the prompt below into a coding agent that has access to the repository.

```text
You are the lead macOS engineer, product designer, test engineer, and release engineer for a native macOS application named LinkShelf.

Your job is NOT to generate the entire application in one uncontrolled code dump.

You must build the product incrementally, using vertical slices, automated tests, small Git commits, and a persistent project tracker so another AI session can continue from exactly where the previous session stopped.

============================================================
PRODUCT VISION
============================================================

Build a native macOS application that acts as a visual link and media workspace.

Users can:

1. Save any website URL.
2. Save video URLs such as YouTube links.
3. Automatically retrieve useful metadata such as:
   - title
   - host/domain
   - favicon
   - preview image / thumbnail when available
   - description when available
4. Hover over a saved item inside the main macOS app to see a polished preview card.
5. Organize links into folders.
6. Create nested folders where useful.
7. Rename, reorder, duplicate, move, archive, and delete folders.
8. Assign each folder:
   - an SF Symbol
   - a custom imported icon/image
   - an optional tint/accent
9. Assign custom icons or thumbnails to individual links.
10. Search links, folders, domains, and tags quickly.
11. Favorite/pin important links.
12. Drag links between folders.
13. Drag URLs from Safari/Chrome into the application.
14. Paste a URL and create a link instantly.
15. Use keyboard shortcuts for fast navigation.
16. Optionally expose a menu-bar experience.
17. Add native macOS WidgetKit widgets to the desktop.
18. Configure each widget to represent a chosen folder or favorites collection.
19. Click a widget item to open the corresponding URL.
20. Keep the experience visually consistent with modern macOS.

The main app is responsible for rich interactions such as hover previews.
WidgetKit widgets are lightweight launchers and information surfaces; do not attempt to force unrestricted hover-driven behavior into WidgetKit.

============================================================
PLATFORM AND STACK
============================================================

Use native Apple technologies wherever practical:

- Swift
- SwiftUI
- AppKit only where SwiftUI does not provide the required macOS behavior
- SwiftData for local persistence
- WidgetKit for desktop widgets
- App Intents for widget configuration/actions
- LinkPresentation for URL metadata
- URLSession for controlled networking when needed
- UniformTypeIdentifiers for drag/drop and icon import
- NSWorkspace for opening external URLs
- App Groups for data shared between the main app and widget extension
- Swift Concurrency: async/await, actors, Sendable where appropriate
- Swift Testing for new unit/integration tests
- XCTest/XCUIAutomation for UI and performance testing
- Xcode previews for isolated UI iteration
- GitHub Actions for continuous integration

Target macOS 14 or newer unless a specific dependency requires changing the target.

Do not use Electron.
Do not use React Native.
Do not recreate native controls unnecessarily.
Do not add third-party dependencies unless they solve a real problem and are documented in DECISIONS.md.

============================================================
DESIGN DIRECTION
============================================================

The app should feel like it belongs on macOS.

Use:
- NavigationSplitView
- native sidebars
- toolbars
- inspectors when appropriate
- context menus
- keyboard navigation
- drag and drop
- system materials
- semantic system colors
- SF Symbols
- restrained animation
- native focus behavior
- large clear spacing
- hierarchy instead of visual clutter
- excellent dark/light mode behavior

Do not blindly copy Apple applications.
Use Apple platform conventions and create an original product identity.

Avoid:
- excessive gradients
- giant rounded cards everywhere
- fake glass effects
- unnecessary shadows
- web-dashboard styling
- inconsistent icon sizes
- over-animation

The user should feel that LinkShelf is a native productivity utility, not a webpage inside a Mac window.

============================================================
CORE APP LAYOUT
============================================================

Use a three-area model where appropriate:

LEFT SIDEBAR
- All Links
- Favorites
- Recent
- Folders
- Tags
- Archive
- Trash
- + New Folder

MAIN CONTENT
- grid/list toggle
- folder header
- saved links
- thumbnails/icons
- sorting
- search/filter state
- drag/drop

OPTIONAL INSPECTOR
- title
- URL
- folder
- tags
- custom icon
- custom thumbnail
- notes
- metadata refresh
- created date
- last opened date

The window must remain useful at smaller widths.

============================================================
FOLDER ICON SYSTEM
============================================================

Folders are a first-class visual organization feature.

Every folder must support:

A. SF Symbol
B. Custom imported icon/image
C. Optional tint
D. Reset to automatic/default icon

Store imported assets inside the app's own container rather than depending permanently on the original file path.

Validate imported files.

Recommended supported formats:
- PNG
- JPEG
- HEIC
- PDF where practical

The UI for choosing an icon should include:
- searchable SF Symbols section
- recent icons
- imported icons
- drag-and-drop import
- tint selector
- live preview
- reset button

The sidebar icon and folder header must use the same FolderIcon model so the visual identity remains consistent.

============================================================
LINK PREVIEW SYSTEM
============================================================

When the pointer remains over a link card for a short debounce interval, show a preview.

Preview should contain, when available:
- preview image
- favicon
- page/video title
- domain
- short description
- tags
- Open button
- Copy Link action

Requirements:
- no preview flicker while quickly moving across cards
- cancel pending metadata/preview work when hover ends
- cache metadata and images
- never block the main actor with network or image decoding work
- provide graceful placeholders
- respect offline state
- provide retry for metadata failures

For MVP, prefer metadata previews over loading arbitrary live webpages.

If a richer Quick-Look-style floating preview is required later, use an AppKit NSPanel integration behind a small abstraction rather than polluting the rest of the SwiftUI codebase.

============================================================
DESKTOP WIDGETS
============================================================

Create a Widget Extension.

Widget configurations should support:
- Favorites widget
- Folder widget
- Recent Links widget

A configurable folder widget should let the user select a LinkShelf folder using AppIntentConfiguration / WidgetConfigurationIntent.

Supported layouts should be adapted for relevant system widget families.

Widget item interaction:
- clicking a saved link opens that URL
- clicking a folder title can deep-link into LinkShelf
- keep widget actions lightweight

The widget must read only the data it requires from the shared App Group storage.

When the app changes widget-visible data, request a WidgetKit timeline reload responsibly.

============================================================
PERSISTENCE MODEL
============================================================

Create domain-oriented models approximately equivalent to:

Folder
- id
- name
- parentFolderID optional
- iconKind
- sfSymbolName optional
- customIconAssetID optional
- tintValue optional
- sortOrder
- createdAt
- updatedAt

LinkItem
- id
- url
- normalizedURL
- title
- host
- summary optional
- faviconAssetID optional
- thumbnailAssetID optional
- customIconAssetID optional
- customThumbnailAssetID optional
- folderID optional
- notes optional
- isFavorite
- isArchived
- createdAt
- updatedAt
- lastOpenedAt optional

Tag
- id
- name

LinkTag
- linkID
- tagID

CachedAsset
- id
- type
- relativePath
- sourceURL optional
- createdAt
- lastAccessedAt

Do not bind every UI view directly to persistence implementation details.

Create repository/service abstractions where they materially improve testability.

============================================================
URL NORMALIZATION
============================================================

Create one URL normalization policy and test it thoroughly.

Examples:
- trim whitespace
- reject unsupported schemes
- allow http/https
- normalize obvious duplicate forms safely
- never modify a URL in a way that changes its intended resource
- preserve meaningful query parameters
- detect exact duplicates
- allow the user to intentionally save a duplicate when explicitly requested

Do not build an aggressive URL tracker-removal feature into MVP.

============================================================
SEARCH
============================================================

Search should match:
- title
- host
- raw URL
- folder
- tags
- notes

Search should be debounced.

Start with deterministic local search.
Do not add an external search service.

============================================================
KEYBOARD-FIRST EXPERIENCE
============================================================

Implement useful shortcuts such as:

⌘N       Add Link
⇧⌘N      New Folder
⌘F       Focus Search
⌘K       Command Palette / Quick Open
⌘1       All Links
⌘2       Favorites
Return    Open selected link
Space     Preview selected item where practical
⌘C       Copy selected link
Delete    Move selected item to Trash

Do not override established macOS shortcuts unexpectedly.

============================================================
MENU BAR
============================================================

After the main application is stable, optionally provide MenuBarExtra.

Menu bar scope:
- quick search
- favorites
- recent links
- add clipboard URL
- open main window

Do not attempt to duplicate the entire application inside the menu bar.

============================================================
PRIVACY AND SECURITY
============================================================

The app must be local-first.

Requirements:
- no analytics in MVP
- no account required
- no server required
- do not upload saved links to a custom backend
- make metadata network requests only when necessary
- use HTTPS when external resources support it
- sanitize and validate URLs
- never execute arbitrary downloaded code
- do not treat fetched metadata as trusted markup
- imported custom icons are copied into controlled app storage
- widget receives minimum required shared data

Document any sandbox entitlements.

============================================================
ARCHITECTURE
============================================================

Prefer a feature-oriented architecture with clear boundaries.

Suggested modules/folders:

LinkShelf/
  App/
  DesignSystem/
  Domain/
  Data/
  Services/
  Features/
    Library/
    Folders/
    LinkEditor/
    Search/
    Preview/
    Settings/
    MenuBar/
  Shared/
  Resources/

LinkShelfWidget/
  Intents/
  Timeline/
  Views/

LinkShelfTests/
  Domain/
  Data/
  Services/
  Features/

LinkShelfUITests/

Docs/
  architecture.md
  testing.md

Use protocols around external effects:
- metadata provider
- URL opener
- clock if time-dependent logic becomes important
- asset store
- link repository
- folder repository

Do not create protocols for trivial pure values merely to claim "clean architecture."

============================================================
SOFTWARE METHODOLOGY
============================================================

Use an iterative, incremental, risk-first methodology combining:

1. Agile vertical slices
2. Test-Driven Development for domain rules and services
3. Behavior/acceptance criteria for product flows
4. Trunk-based development on main for a solo developer
5. Continuous Integration
6. Definition of Done gates

For each feature:

PLAN
- state user story
- define acceptance criteria
- identify edge cases

RED
- write failing unit tests for deterministic logic

GREEN
- implement minimum code needed

REFACTOR
- clean implementation while tests remain green

INTEGRATE
- connect UI/data/services
- run targeted and full tests

VERIFY
- manually test visual/macOS-specific behavior

DOCUMENT
- update PROJECT_TRACKER.md
- update DECISIONS.md if architecture changed
- update CHANGELOG.md for meaningful user-visible changes

COMMIT
- make one coherent Git commit

Do not merge multiple unrelated features into one commit.

============================================================
TESTING STRATEGY
============================================================

Follow a test pyramid.

UNIT TESTS - largest layer
Test:
- URL validation
- URL normalization
- duplicate detection
- folder validation
- nested folder cycle prevention
- folder ordering
- icon selection state
- search filtering/ranking
- metadata mapping
- cache expiry rules
- file naming and storage logic
- command handlers
- widget view model generation
- deep-link construction/parsing

INTEGRATION TESTS
Test:
- SwiftData repositories with temporary/in-memory storage
- metadata service with URLProtocol/mock transport
- icon import + asset storage
- link creation end-to-end below UI
- move link between folders
- deleting folder behavior
- widget shared-store read
- migration behavior once migrations exist

UI TESTS WITH XCTEST/XCUIAUTOMATION
Test:
- launch app
- create folder
- change folder icon
- import custom folder icon
- add link
- edit link
- move link
- favorite link
- search
- open context menu
- delete/restore
- keyboard shortcuts
- empty states
- error state
- offline metadata state

PERFORMANCE TESTS
Measure:
- startup with realistic library
- search with thousands of links
- scrolling large grids
- metadata caching
- thumbnail decoding
- persistence fetches

MANUAL ACCESSIBILITY/VISUAL MATRIX
Verify:
- Light Mode
- Dark Mode
- Increased contrast where practical
- Reduced motion
- keyboard-only operation
- VoiceOver labels
- focus order
- small window
- large window
- multiple displays
- Retina scaling

Never claim a feature is "fully tested" merely because the app compiles.

============================================================
QUALITY GATES
============================================================

A milestone is complete only when:

- project builds with zero errors
- new compiler warnings are resolved
- unit tests pass
- integration tests pass
- relevant UI tests pass
- no knowingly broken navigation
- empty/loading/error states exist
- feature works in Light and Dark Mode
- keyboard path is considered
- accessibility labels are present for important controls
- PROJECT_TRACKER.md is updated
- git working tree is intentionally reviewed
- commit is created with a meaningful message

============================================================
PROJECT CONTINUITY / NEW CHAT RULE
============================================================

The repository MUST contain:

PROJECT_TRACKER.md
DECISIONS.md
CHANGELOG.md

PROJECT_TRACKER.md is the source of truth for implementation progress.

At the beginning of EVERY new coding session or AI chat:

1. Read PROJECT_TRACKER.md completely.
2. Read DECISIONS.md.
3. Run git status.
4. Inspect recent commits:
   git log --oneline -10
5. Run the test suite or the smallest relevant health check.
6. Determine the first unfinished task.
7. Continue from there instead of rebuilding completed work.

At the end of EVERY session:

1. Update Completed.
2. Update In Progress.
3. Update Next.
4. Record blockers.
5. Record tests run and results.
6. Record important files changed.
7. Update DECISIONS.md when a durable technical choice was made.
8. Commit the coherent work.

PROJECT_TRACKER.md should contain:

# Current Milestone
# Completed
# In Progress
# Next
# Blockers
# Known Bugs
# Test Status
# Important Files
# Last Commit
# Next Recommended Commit

Never infer progress from memory when the repository tracker exists.
The repository state wins.

============================================================
GIT / GITHUB WORKFLOW
============================================================

GitHub owner:
Geltrax69

Suggested repository:
Geltrax69/linkshelf-macos

Use the user's existing kickbacks scripts.

For important milestone commits use:

repo linkshelf-macos

Review staged changes before accepting the commit.

Use conventional-style commit messages such as:

docs: define product architecture and delivery plan
chore: scaffold macOS app and widget targets
style: add native design system primitives
feat: add folder persistence and custom icon model
test: cover folder validation and ordering
feat: add link creation and url normalization
test: cover url normalization and duplicates
feat: add metadata preview service
feat: add hover preview experience
feat: add library search and filters
feat: add drag and drop organization
feat: add configurable folder widget
test: add widget and shared-store coverage
feat: add menu bar quick access
test: add core ui workflows
perf: optimize thumbnail caching and search
docs: add release and testing documentation
chore: prepare first beta

Use `ac` only for low-risk unattended commits where its path-based guessed message is acceptable.
Use `repo` when the exact commit message matters.

Never make a giant "final app" commit.

============================================================
IMPLEMENTATION ORDER
============================================================

Build in this order:

M0 - repository and engineering documentation
M1 - Xcode scaffold and app shell
M2 - design system and navigation
M3 - Folder model + persistence + custom folder icons
M4 - Link model + add/edit/delete
M5 - URL normalization and duplicate handling
M6 - metadata + favicon/thumbnail cache
M7 - visual link cards + hover preview
M8 - drag/drop + sorting + folders
M9 - search + favorites + recents
M10 - WidgetKit extension + App Group + folder widgets
M11 - menu bar + keyboard productivity
M12 - accessibility + performance + error handling
M13 - full regression/UI testing
M14 - beta packaging and release documentation

Do not start the widget before the persistence model is stable enough to share safely.

============================================================
FIRST TASK
============================================================

Before writing production code:

1. Inspect repository state.
2. Create PROJECT_TRACKER.md.
3. Create DECISIONS.md.
4. Create CHANGELOG.md.
5. Create a minimal README.md.
6. Write the milestone checklist.
7. Commit documentation.
8. Scaffold the macOS Xcode project.
9. Add a test target immediately.
10. Make the first application shell build and test successfully.

Then stop and report:
- files created
- tests run
- commit created
- current tracker state
- next milestone

Do not jump ahead.
```

---

# 2. WHAT WE ARE MAKING

**LinkShelf** is a native macOS visual bookmark and workspace manager.

A normal browser bookmark system is usually a long text hierarchy. LinkShelf makes saved resources feel more like a visual Mac workspace.

A saved item can represent:

- a website
- documentation
- GitHub repository
- YouTube/video link
- article
- design reference
- college portal
- project dashboard
- deployment URL
- research source
- anything addressable by an `http` or `https` URL

The app stores the URL plus useful presentation data such as title, favicon, preview image, description, folder, tags, custom icon, notes, and favorite state.

The main experience is:

```text
Save → Organize → Preview → Search → Open
```

A user should be able to save a URL in seconds and later find it visually without remembering the exact title or browser folder.

---

# 3. PRODUCT EXPERIENCE

## 3.1 Main window

Suggested structure:

```text
┌──────────────────────────────────────────────────────────────────────┐
│ LinkShelf                         Search...        + Add Link    ••• │
├───────────────────┬──────────────────────────────────────────────────┤
│ Library           │ Development                                     │
│                   │ 24 saved items                       Grid ▦      │
│ All Links         │                                                  │
│ Favorites         │ ┌───────────┐ ┌───────────┐ ┌───────────┐       │
│ Recent            │ │ thumbnail │ │ thumbnail │ │ thumbnail │       │
│                   │ │ GitHub    │ │ Swift     │ │ YouTube   │       │
│ FOLDERS           │ │ github... │ │ apple...  │ │ youtube.. │       │
│ 💻 Development    │ └───────────┘ └───────────┘ └───────────┘       │
│ 🎓 College        │                                                  │
│ ◈ Design          │ ┌───────────┐ ┌───────────┐ ┌───────────┐       │
│ ⌘ Research        │ │ ...       │ │ ...       │ │ ...       │       │
│                   │ └───────────┘ └───────────┘ └───────────┘       │
│ + New Folder      │                                                  │
└───────────────────┴──────────────────────────────────────────────────┘
```

Use a standard macOS toolbar instead of making a fake custom title bar unless a later design iteration proves there is a strong reason.

---

# 4. HOVER PREVIEW

Hovering should make the app feel substantially better than ordinary bookmarks.

Example:

```text
             pointer
                ↓
       ┌────────────────────────────┐
       │ [      thumbnail       ]   │
       │                            │
       │ Building a Swift Mac App   │
       │ youtube.com                │
       │                            │
       │ Native macOS development   │
       │ walkthrough...             │
       │                            │
       │ Swift   macOS   Tutorial   │
       │                            │
       │ Copy Link        Open ↗    │
       └────────────────────────────┘
```

### Behavior

- Start opening after roughly 200–350 ms of stable hover.
- Cancel when pointer exits before the delay.
- Do not refetch metadata every hover.
- Position the preview where it remains visible inside the active screen.
- If there is no image, use favicon + title + tasteful placeholder.
- Avoid opening a full embedded browser in the first version.

### Important WidgetKit distinction

Rich pointer-hover previews belong in the **main application**.

A native desktop WidgetKit widget should remain a lightweight system widget with click/tap actions and configuration. Do not architect the project around forcing main-app hover behavior into WidgetKit.

---

# 5. FOLDERS AND CUSTOM FOLDER ICONS

Folders are more than text labels.

A folder could look like:

```text
💻  Development
🎓  College
◇   Design
⌘   Research
▶   Videos
☁   Cloud
```

The icon editor should provide three sources.

## SF Symbols

Native, scalable, consistent with macOS.

Examples:

- `hammer`
- `graduationcap`
- `paintpalette`
- `book.closed`
- `play.rectangle`
- `cloud`
- `shippingbox`
- `terminal`
- `curlybraces`
- `folder`

## Imported custom icon

The user can select or drag an image.

Flow:

```text
Folder Settings
      │
      ├── Name
      │     Development
      │
      ├── Icon
      │     [ SF Symbols ]
      │     [ Custom ]
      │
      ├── Import Image...
      │
      ├── Tint
      │
      └── Save
```

The imported icon is copied into application-controlled storage.

Do not store a fragile absolute path to the original Downloads/Desktop file.

## Tint

The user can optionally assign a color tint.

The application should still preserve contrast automatically in Light and Dark Mode.

---

# 6. VISUAL DESIGN SYSTEM

Create a small internal `DesignSystem` instead of scattering arbitrary values throughout the app.

Possible tokens:

```swift
enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
}

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}
```

Do not treat the numbers as immutable Apple rules. They are product tokens that should be adjusted through visual testing.

## Visual principles

### Hierarchy over decoration

A folder name, thumbnail, link title, and metadata should have obvious hierarchy.

### System color first

Prefer semantic colors such as primary/secondary/system background equivalents instead of hard-coding RGB values throughout the application.

### Materials with restraint

Use system materials for sidebars, transient popovers, inspectors, and panels when they improve depth.

Do not place blur behind every card.

### Typography

Prefer San Francisco through system text styles.

Do not bundle or imitate Apple font files.

### Icons

Use SF Symbols as the default icon language.

Custom folder icons are an enhancement, not a replacement for consistent action icons.

For example:
- Add → `plus`
- Search → `magnifyingglass`
- Favorite → `star`
- Folder → `folder`
- Delete → `trash`
- Copy → `doc.on.doc`
- Open external → suitable system symbol
- Settings → `gearshape`

### Motion

Use short transitions to clarify:
- hover
- selection
- insertion
- folder expansion
- preview appearance

Avoid decorative continuous animations.

### Empty states

Empty state example:

```text
        [link symbol]

No links in Development

Drop a URL here or add your first link.

        [ Add Link ]
```

The app should look intentional even when there is no data.

---

# 7. TECH STACK

| Area | Technology | Why |
|---|---|---|
| Language | Swift | Native Apple language |
| Main UI | SwiftUI | Modern native declarative UI |
| macOS-specific UI | AppKit | Panels, fine pointer/window behavior when necessary |
| Persistence | SwiftData | Native model persistence and SwiftUI integration |
| Metadata | LinkPresentation | Native URL metadata retrieval |
| Networking | URLSession | Controlled fallback/network requests |
| Concurrency | async/await + actors | Safe asynchronous metadata and cache work |
| Desktop widgets | WidgetKit | Native macOS widgets |
| Widget configuration | App Intents | User-selected folder/favorites widget |
| Shared app/widget data | App Groups | Controlled cross-target data access |
| System links | NSWorkspace | Open saved URLs in user's browser |
| Drag/drop | SwiftUI + UTType | Native drag/drop |
| Unit tests | Swift Testing | Modern Swift unit/integration tests |
| UI tests | XCTest/XCUIAutomation | Automated user-flow validation |
| CI | GitHub Actions | Build/test each push/PR |
| Package management | Swift Package Manager | Use only when dependencies are justified |

---

# 8. WHY NATIVE SWIFT INSTEAD OF ELECTRON

This product is tightly tied to macOS:

- desktop widgets
- menu bar
- App Intents
- system materials
- pointer interactions
- drag/drop
- SF Symbols
- keyboard commands
- App Sandbox
- App Groups
- native window behavior

Using SwiftUI keeps those integrations direct and reduces the amount of platform bridging.

---

# 9. APP ARCHITECTURE

Use feature-oriented organization with clear domain/data boundaries.

```text
LinkShelf/
├── App/
│   ├── LinkShelfApp.swift
│   ├── AppEnvironment.swift
│   └── RootView.swift
│
├── DesignSystem/
│   ├── Tokens/
│   ├── Components/
│   ├── Icons/
│   └── Modifiers/
│
├── Domain/
│   ├── Models/
│   ├── Repositories/
│   ├── UseCases/
│   └── Errors/
│
├── Data/
│   ├── SwiftData/
│   ├── Repositories/
│   ├── Migrations/
│   └── AssetStore/
│
├── Services/
│   ├── Metadata/
│   ├── URLNormalization/
│   ├── Search/
│   ├── OpenURL/
│   └── Cache/
│
├── Features/
│   ├── Library/
│   ├── FolderDetail/
│   ├── FolderEditor/
│   ├── LinkEditor/
│   ├── Search/
│   ├── Preview/
│   ├── Settings/
│   └── MenuBar/
│
└── Resources/

LinkShelfWidget/
├── LinkShelfWidgetBundle.swift
├── Intents/
├── Providers/
├── Models/
└── Views/

LinkShelfTests/
├── Domain/
├── Data/
├── Services/
└── Features/

LinkShelfUITests/
└── UserFlows/
```

The goal is not maximum abstraction.

The goal is code that is:
- understandable
- replaceable
- testable
- independently evolvable

---

# 10. DATA SHARING WITH WIDGETS

The main application and Widget Extension need an **App Group**.

Conceptually:

```text
Main App
   │
   ├── writes data
   ├── manages metadata
   ├── manages custom icons
   │
   ▼
Shared App Group
   │
   ▼
Widget Extension
   └── reads minimal presentation data
```

Avoid having the widget perform expensive metadata fetching.

The app should prepare what the widget needs.

After a folder or link changes:

```text
Persist
   ↓
Update shared representation if needed
   ↓
Request WidgetKit timeline reload
```

---

# 11. LINK ADDING FLOW

## Method 1 — Add button

```text
+ Add Link
    ↓
Paste URL
    ↓
Validate
    ↓
Create provisional item
    ↓
Fetch metadata
    ↓
Show editable preview
    ↓
Choose folder/tags
    ↓
Save
```

## Method 2 — Drag from browser

```text
Safari/Chrome URL
       ↓ drag
Folder / content grid
       ↓
URL validation
       ↓
Link editor or instant save
```

## Method 3 — Clipboard quick add

Later, the menu-bar utility can detect that the clipboard currently contains a valid URL after the user explicitly chooses **Add Clipboard Link**.

Do not continuously inspect the clipboard in the background for MVP.

---

# 12. METADATA PIPELINE

```text
URL
 ↓
URLNormalizer
 ↓
DuplicateDetector
 ↓
MetadataService
 ↓
LPMetadataProvider
 ↓
Normalized Metadata DTO
 ├── title
 ├── description
 ├── icon
 └── image
 ↓
AssetStore
 ↓
SwiftData
 ↓
UI refresh
```

The UI should not know how `LPMetadataProvider` works.

Example abstraction:

```swift
protocol LinkMetadataProviding {
    func metadata(for url: URL) async throws -> LinkMetadata
}
```

That makes the behavior mockable in tests.

---

# 13. CACHE STRATEGY

Store thumbnails/icons on disk rather than stuffing large image blobs into normal model rows.

```text
Application Support/
└── LinkShelf/
    └── Assets/
        ├── favicons/
        ├── thumbnails/
        └── custom-icons/
```

Database stores an asset ID or relative path.

Use:
- in-memory decoded image cache
- disk cache
- controlled size limits
- background cleanup
- placeholder while loading

Never decode large images repeatedly on the main thread.

---

# 14. SEARCH EXPERIENCE

Search should feel instantaneous.

Example:

```text
⌘K
┌─────────────────────────────────────────────┐
│ unity                                       │
├─────────────────────────────────────────────┤
│ Unity Documentation               Docs      │
│ Unity Game Tutorial               YouTube   │
│ My Unity Project Dashboard        Dev       │
└─────────────────────────────────────────────┘
```

Start local.

No AI search is necessary for V1.

Ranking can prioritize:

1. exact title prefix
2. title contains
3. host
4. tags
5. folder
6. notes/URL

Write tests for ranking so behavior remains deterministic.

---

# 15. DESKTOP WIDGET DESIGNS

## Small

```text
┌──────────────────────┐
│ 💻 Development       │
│                      │
│ GitHub               │
│ Swift Docs           │
│ Deployment           │
│ YouTube              │
└──────────────────────┘
```

## Medium

```text
┌─────────────────────────────────────────┐
│ 💻 Development                       ›  │
│                                         │
│ [GH] GitHub       [S] Swift Docs        │
│ [▶] Tutorial      [☁] Deployment        │
└─────────────────────────────────────────┘
```

## Favorites

```text
┌─────────────────────────────────────────┐
│ ★ Favorites                             │
│ GitHub     ChatGPT     Docs     Figma   │
└─────────────────────────────────────────┘
```

Use the system widget environment instead of fighting it with custom window-like chrome.

---

# 16. OPTIONAL MENU BAR EXPERIENCE

```text
LinkShelf
────────────────────
Search...
★ Favorites
Recent
────────────────────
Add Clipboard Link
Open LinkShelf
```

Possible implementation: `MenuBarExtra`.

This is a later milestone after the main library experience is stable.

---

# 17. SOFTWARE DEVELOPMENT METHODOLOGY

Use **Iterative Incremental Development + Vertical Slices + TDD + Continuous Integration**.

## Why this fits LinkShelf

The project touches several independent risk areas:

- persistence
- metadata/networking
- native drag/drop
- custom asset storage
- hover interaction
- WidgetKit
- App Group data
- macOS window behavior

Trying to build all of them simultaneously creates a large debugging surface.

Instead:

```text
Small feature
    ↓
Tests
    ↓
Implementation
    ↓
Manual verification
    ↓
Commit
    ↓
Next feature
```

---

# 18. TDD LOOP

For deterministic logic:

```text
RED
write failing test

GREEN
implement minimum behavior

REFACTOR
improve structure

RUN
all relevant tests

COMMIT
small coherent change
```

Example:

### Story

> As a user, I can paste a URL with accidental surrounding spaces and LinkShelf saves the correct URL.

### Red

```swift
@Test
func trimsWhitespaceAroundURL() {
    // failing expectation first
}
```

### Green

Implement trimming in `URLNormalizer`.

### Refactor

Move URL policy into a dedicated value/service.

### Commit

```text
feat: normalize pasted urls
```

---

# 19. DEFINITION OF DONE

A task cannot be marked complete only because the screen appears.

A feature is Done when:

- [ ] acceptance criteria satisfied
- [ ] error states handled
- [ ] loading state handled if relevant
- [ ] empty state handled if relevant
- [ ] unit tests added
- [ ] integration tests added where needed
- [ ] UI test added for critical workflow
- [ ] Light Mode checked
- [ ] Dark Mode checked
- [ ] keyboard navigation checked
- [ ] accessibility labels checked
- [ ] no new compiler warnings
- [ ] project builds
- [ ] test suite passes
- [ ] tracker updated
- [ ] change committed

---

# 20. TEST PYRAMID

Apple's modern Xcode testing guidance supports combining many fast isolated tests with fewer integration and UI tests.

For LinkShelf:

```text
               /\
              /UI\
             /----\
            / INT  \
           /--------\
          /   UNIT   \
         /____________\
```

## Target philosophy

Do not chase an arbitrary coverage number.

Instead require strong coverage of risky deterministic logic.

A reasonable engineering target is:
- very high coverage for URL/domain/search/data rules
- strong integration coverage for repositories and asset storage
- selected UI coverage for critical flows
- manual visual verification for system appearance

---

# 21. UNIT TEST CASES

## URLNormalizer

- valid HTTPS URL
- valid HTTP URL
- whitespace around URL
- missing URL
- invalid string
- unsupported scheme
- uppercase host
- query parameters preserved
- fragments preserved where intended
- Unicode URL
- duplicate-equivalent normalized URL
- URL that must not be over-normalized

## Folder rules

- create valid folder
- empty name rejected
- whitespace-only name rejected
- rename
- custom SF Symbol
- imported icon
- tint
- reorder
- nested folder
- cannot make folder its own parent
- cannot create ancestor cycle
- deleting parent behavior follows defined policy

## Search

- exact title first
- title prefix
- host match
- tag match
- folder match
- notes match
- no results
- case-insensitive
- deterministic ordering

## Metadata

- successful metadata
- no title
- no image
- no favicon
- timeout
- cancellation
- offline/network failure
- invalid metadata
- fallback title
- cached response

## Asset store

- save imported icon
- unique file names
- load asset
- remove unused asset
- reject unsupported input
- handle corrupted file
- safe relative path
- no directory traversal

## Favorites/recents

- favorite toggle
- favorites query
- last-opened updates
- recents sorting

---

# 22. INTEGRATION TEST CASES

Use an isolated temporary database/container.

Test:

```text
Create Folder
  ↓
Create Link
  ↓
Persist
  ↓
Reload repository
  ↓
Link still belongs to Folder
```

Also:

- move link between folders
- persist custom folder icon ID
- delete link and clean orphaned assets
- restore trashed link
- metadata result stored
- database survives repository recreation
- widget-readable representation updates

For network behavior, use a mock transport or `URLProtocol` approach instead of hitting live production websites in the test suite.

Tests should be repeatable offline.

---

# 23. UI AUTOMATION TEST CASES

Critical workflows:

### Test 1 — Create folder

```text
Launch
→ New Folder
→ type "Development"
→ choose icon
→ Save
→ folder appears in sidebar
```

### Test 2 — Custom folder icon

```text
Development
→ Edit
→ Custom Icon
→ Import fixture image
→ Save
→ new icon visible in sidebar and folder header
```

### Test 3 — Add link

```text
Add Link
→ paste fixture URL
→ save
→ card appears
```

Metadata should be mocked/controlled where possible.

### Test 4 — Move link

```text
Select card
→ move/drag to College
→ open College
→ card exists
```

### Test 5 — Search

```text
Add known links
→ ⌘F
→ search unique title
→ expected card visible
```

### Test 6 — Favorite

```text
Favorite link
→ Favorites
→ item appears
```

### Test 7 — Trash/restore

```text
Delete
→ Trash
→ Restore
→ original collection contains item
```

---

# 24. PERFORMANCE TESTING

Create fixture generators for:

- 100 links
- 1,000 links
- 5,000 links
- 10,000 links

Measure:

- cold launch
- initial fetch
- search latency
- folder switching
- grid scroll
- icon decode
- thumbnail decode
- metadata cache lookup

The app should degrade gracefully instead of loading every thumbnail at full resolution immediately.

---

# 25. ACCESSIBILITY

Every important icon-only button must have an accessibility label.

Examples:

```text
star icon
Accessibility label: "Add to Favorites"

ellipsis
Accessibility label: "More Actions"

custom folder icon button
Accessibility label: "Change Folder Icon"
```

Verify keyboard focus order.

Do not communicate state using color alone.

Respect reduced motion.

---

# 26. ERROR DESIGN

Errors should be actionable.

Bad:

```text
Something went wrong.
```

Better:

```text
Preview couldn't be loaded.

The link is saved, but the website didn't provide preview metadata.

[ Retry ] [ Keep Without Preview ]
```

The user should not lose a link merely because metadata retrieval failed.

---

# 27. OFFLINE BEHAVIOR

The app is still useful offline.

Available offline:

- existing folders
- existing saved links
- cached thumbnails
- custom icons
- search
- edit/delete/reorganize

Unavailable or degraded:

- fetching new metadata
- refreshing remote thumbnails
- opening remote pages

A newly entered link can still be saved without metadata.

---

# 28. PRIVACY

V1 should be local-first.

Do not require:
- account
- custom backend
- analytics SDK
- telemetry SDK

Optional iCloud sync can be a later feature after the local data model and migrations are stable.

---

# 29. PROJECT TRACKING FOR AI CONTEXT SWITCHING

This is mandatory if multiple AI chats will work on the project.

Create:

```text
PROJECT_TRACKER.md
DECISIONS.md
CHANGELOG.md
```

## PROJECT_TRACKER.md template

```markdown
# LinkShelf Project Tracker

## Current Milestone
M3 — Folder System

## Current Build Status
Build: PASS
Unit Tests: PASS
Integration Tests: PASS
UI Tests: NOT RUN

## Completed
- [x] Xcode project scaffold
- [x] Main NavigationSplitView
- [x] Folder SwiftData model

## In Progress
- [ ] Custom folder icon importer

## Next
- [ ] Folder icon picker
- [ ] Persist imported icon
- [ ] Add tests
- [ ] Commit milestone

## Blockers
None

## Known Bugs
None

## Important Files
- LinkShelf/Domain/Models/Folder.swift
- LinkShelf/Features/FolderEditor/FolderEditorView.swift
- LinkShelf/Data/AssetStore/DiskAssetStore.swift

## Tests Last Run
Command:
xcodebuild test ...

Result:
PASS

## Last Commit
abc1234 feat: add folder persistence

## Next Recommended Commit
feat: add custom folder icons
```

## DECISIONS.md template

```markdown
# Architecture Decisions

## ADR-001 — Native SwiftUI
Status: Accepted

Context:
The product depends heavily on macOS-native integrations.

Decision:
Use SwiftUI with focused AppKit bridges.

Consequences:
Better native integration; macOS-specific codebase.
```

## New AI chat startup rule

A new agent must **not** ask, "What have we completed?" when repository access exists.

It must inspect:

```bash
cat PROJECT_TRACKER.md
cat DECISIONS.md
git status
git log --oneline -10
```

Then continue the first unfinished task.

---

# 30. GITHUB REPOSITORY SETUP

Your existing Git identity:

```bash
git config --global user.name "Geltrax69"
git config --global user.email "144154602+Geltrax69@users.noreply.github.com"
```

Check authentication:

```bash
gh auth status
```

Suggested repository:

```text
Geltrax69/linkshelf-macos
```

Using your script:

```bash
repo linkshelf-macos
```

Because `repo` already handles:
- GitHub lookup
- cloning when remote exists
- asking before creating a public repo
- wiring `origin`
- staging
- reviewing staged files
- commit message
- push

it should be the preferred command for meaningful project milestones.

---

# 31. KICKBACKS WORKFLOW

## `repo` — one repo, interactively

```bash
repo kickbacks     # or just `repo` and it asks
```

1. Looks up `Geltrax69/<name>` on GitHub.
2. If it exists and I don't have it locally, clones it to `~/PROJECTS/<name>`.
3. If it doesn't exist, asks first, then creates it **public** and wires `origin`.
4. Stages everything and prints what changed.
5. Lets me unstage paths I don't want in this commit (blank = commit all).
6. Asks for a message (Enter accepts `update N file(s)`).
7. Commits and pushes.

## `ac` — many repos, unattended

```bash
ac                    # every repo listed in ~/.ac-repos
ac ~/PROJECTS/foo     # just one
AC_PUSH=0 ac          # commit but don't push
```

Walks each repo, stages everything, and commits with a message guessed from the
changed file paths — `test:`, `docs:`, `chore:`, `style:`, else `feat:`. Skips
repos with nothing staged.

The guess comes from paths, not from reading the diff. It's honest but dumb;
use `repo` when the message matters.

## Setup

```bash
git config --global user.name  "Geltrax69"
git config --global user.email "144154602+Geltrax69@users.noreply.github.com"
```

The noreply address is what makes commits count as mine on GitHub without
leaking my real email — required, since "Keep my email addresses private" is on.

Auth is `gh` (`repo` scope). Both scripts live in `~/bin`, which is on `PATH`
via `~/.zshrc`.

---

# 32. HOW TO USE KICKBACKS FOR THIS PROJECT

For important commits:

```bash
cd ~/PROJECTS/linkshelf-macos
repo linkshelf-macos
```

When asked for the commit message, use the planned milestone message.

Example:

```text
feat: add folder persistence and custom icons
```

Use `ac` for lower-risk housekeeping where an automatically guessed commit prefix is acceptable.

Example:

```bash
ac ~/PROJECTS/linkshelf-macos
```

Avoid `ac` immediately after a large mixed change because it does not understand the semantic purpose of the diff.

---

# 33. PROGRESSIVE COMMIT PLAN

The project should tell a story when somebody reads the Git history.

## Milestone 0 — Planning

```text
docs: add linkshelf product and engineering blueprint
docs: add project tracker and architecture decisions
```

## Milestone 1 — Scaffold

```text
chore: scaffold native macOS application
chore: add unit and ui test targets
chore: add widget extension target
```

## Milestone 2 — App shell

```text
feat: add library navigation shell
style: add native macOS design system
test: add app launch smoke tests
```

## Milestone 3 — Folders

```text
feat: add folder domain model
feat: persist folders with swiftdata
test: cover folder persistence
feat: add folder creation and editing
feat: add sf symbol folder icons
feat: add custom folder icon import
test: cover folder icon storage
feat: add folder reordering
test: prevent invalid nested folder cycles
```

## Milestone 4 — Links

```text
feat: add link domain model
feat: add link editor
feat: add url normalization
test: cover url validation and normalization
feat: add duplicate link handling
test: cover duplicate behavior
```

## Milestone 5 — Metadata

```text
feat: add link metadata provider
test: cover metadata mapping and failures
feat: add disk asset cache
test: cover asset storage
feat: add favicon and thumbnail presentation
```

## Milestone 6 — Visual library

```text
feat: add visual link cards
style: polish library grid and list layouts
feat: add hover link previews
test: cover preview state transitions
```

## Milestone 7 — Organization

```text
feat: add link drag and drop
feat: add link sorting
feat: add tags
feat: add favorites and recents
test: cover organization rules
```

## Milestone 8 — Search

```text
feat: add local library search
test: cover search ranking
feat: add command palette
test: cover command actions
```

## Milestone 9 — Widgets

```text
chore: configure shared app group
feat: add widget shared data adapter
test: cover widget shared data
feat: add configurable folder widget
feat: add favorites widget
feat: add recent links widget
test: cover widget timeline generation
```

## Milestone 10 — macOS productivity

```text
feat: add keyboard navigation
feat: add menu bar quick access
feat: add clipboard quick add
test: cover keyboard commands
```

## Milestone 11 — Reliability

```text
fix: harden metadata failure handling
perf: optimize thumbnail loading
perf: optimize large library search
test: add critical ui regression flows
test: add performance coverage
```

## Milestone 12 — Beta

```text
docs: add privacy and support documentation
docs: add beta test checklist
chore: prepare linkshelf beta release
```

---

# 34. EXAMPLE DAILY DEVELOPMENT LOOP

Start:

```bash
cd ~/PROJECTS/linkshelf-macos

cat PROJECT_TRACKER.md
git status
git log --oneline -10
```

Run current tests.

Work on **one coherent task**.

Example:

```text
Task:
Custom folder icons
```

Development:

```text
1. Write/import validation tests.
2. Run tests → expected failure.
3. Implement icon import.
4. Store imported icon in app-controlled directory.
5. Run tests.
6. Connect Folder Editor UI.
7. Test Light/Dark Mode.
8. Test icon replacement.
9. Test reset.
10. Update PROJECT_TRACKER.md.
```

Then:

```bash
repo linkshelf-macos
```

Commit:

```text
feat: add custom folder icon import
```

Next task begins only after the repository is clean or the remaining uncommitted work is intentional and recorded.

---

# 35. CI PIPELINE

Create GitHub Actions after the Xcode project stabilizes.

Conceptual pipeline:

```text
Push / Pull Request
       ↓
Resolve packages
       ↓
Build
       ↓
Unit Tests
       ↓
Integration Tests
       ↓
Selected UI Tests
       ↓
Report
```

The exact `xcodebuild` command depends on the generated scheme and destination.

Typical shape:

```bash
xcodebuild \
  -scheme LinkShelf \
  -destination 'platform=macOS' \
  test
```

Do not copy a CI command blindly. Verify the actual shared scheme name generated by Xcode.

---

# 36. BRANCHING STRATEGY

For a solo project, keep branching simple.

Primary:

```text
main
```

Small risky experiments may use:

```text
feature/widget-app-group
feature/hover-panel
```

But do not create a branch for every two-line change.

The target workflow is essentially trunk-based development with small, buildable commits.

---

# 37. PULL REQUEST CHECKLIST

Even as a solo developer, PRs can be useful for larger milestones.

```markdown
## What changed?

## Why?

## Screenshots / recordings

## Tests
- [ ] Unit
- [ ] Integration
- [ ] UI
- [ ] Manual Light Mode
- [ ] Manual Dark Mode

## Risks

## Tracker updated?
- [ ] Yes
```

---

# 38. CODE REVIEW CHECKLIST

Before accepting a coding-agent change:

### Correctness
- Does it satisfy the acceptance criteria?
- Is failure behavior defined?
- Are async tasks cancelled correctly?

### Architecture
- Is business logic trapped inside a View?
- Are persistence/network effects mockable where necessary?
- Did the agent introduce unnecessary abstractions?

### macOS UX
- Does it use native controls?
- Does keyboard navigation work?
- Is pointer behavior sensible?
- Does Dark Mode work?

### Performance
- Is disk/network work happening off the main actor?
- Are images being decoded repeatedly?
- Is the whole database loaded for every query?

### Tests
- Did the tests fail before the implementation when using TDD?
- Do tests verify behavior instead of implementation details?
- Are network tests deterministic?

### Git
- Is the commit coherent?
- Does the message describe the actual change?
- Is the tracker updated?

---

# 39. FEATURE PRIORITY

## P0 — Required for first usable version

- native app shell
- folders
- custom folder icons
- save links
- metadata
- visual cards
- hover preview
- search
- favorites
- drag/drop organization
- local persistence
- testing
- desktop folder widget

## P1 — Strong product improvements

- tags
- command palette
- menu bar
- quick-add clipboard
- recents widget
- import/export
- archive/trash
- keyboard navigation polish

## P2 — Future

- iCloud sync
- Safari extension
- share extension
- browser import
- smart folders
- automatic duplicate cleanup suggestions
- Spotlight integration
- multiple workspaces
- backup/restore
- richer preview renderer

Do not let P2 delay the polished P0 experience.

---

# 40. SMART FOLDERS — FUTURE

Later, LinkShelf can have dynamic collections.

Examples:

```text
Recently Added
Opened This Week
GitHub
YouTube
Unread
Favorites
No Folder
Missing Preview
```

A Smart Folder is a saved query rather than a physical parent folder.

Do not mix this with basic folders during the first persistence milestone.

---

# 41. IMPORT / EXPORT — FUTURE

Useful export format:

```json
{
  "version": 1,
  "folders": [],
  "links": [],
  "tags": []
}
```

Custom image assets can be placed inside an exported package/archive later.

This creates a recovery path and reduces vendor lock-in.

---

# 42. FIRST RUN EXPERIENCE

Keep onboarding tiny.

```text
Welcome to LinkShelf

Save your important links.
Organize them visually.
Open them from your Mac or desktop widgets.

[ Create My First Folder ]
[ Add a Link ]
```

Do not require a multi-page tutorial.

Use contextual empty states instead.

---

# 43. EXAMPLE FIRST WORKSPACE

```text
Development
├── GitHub
├── Swift Documentation
├── Apple Developer
├── Stack Overflow
├── Deployment Dashboard
└── YouTube Tutorial

College
├── University Portal
├── Course Notes
└── Assignments

Design
├── Figma
├── Inspiration
└── Icons
```

The app becomes useful immediately without requiring a complicated taxonomy.

---

# 44. APP SETTINGS

Potential V1 settings:

```text
General
- Open links in default browser
- Show hover previews
- Hover preview delay
- Default link view: Grid / List
- Default new-link folder

Appearance
- Follow system appearance
- Thumbnail size
- Sidebar icon size where supported

Data
- Clear metadata cache
- Export Library
- Import Library

Widgets
- Explain how to configure LinkShelf widgets
```

Do not add settings for things that can be handled naturally by macOS.

---

# 45. POLISH DETAILS

Small details that will make the product feel significantly better:

- context menu on every link
- context menu on every folder
- drag highlight
- subtle selection state
- correct cursor behavior
- keyboard focus ring
- undo for destructive operations where practical
- confirmation only for genuinely destructive actions
- inline rename
- copy URL
- reveal folder
- refresh metadata
- use custom thumbnail
- reset thumbnail
- multi-select links
- bulk move
- proper window restoration
- remember grid/list preference
- remember sidebar expansion state
- excellent empty states
- no flashing when thumbnails load
- placeholders with consistent aspect ratio

---

# 46. WHAT NOT TO BUILD FIRST

Do **not** start with:

- AI recommendations
- cloud backend
- collaboration
- accounts
- subscriptions
- cross-platform support
- browser extensions
- live webpage embedding everywhere
- automated screenshot crawler
- complicated sync conflict engine

Build the Mac utility first.

---

# 47. RISKS

## Metadata inconsistency

Different sites expose different metadata.

Mitigation:
- strong fallbacks
- custom user overrides
- cache successful data
- allow saving without metadata

## Widget data sharing

The widget is a separate extension.

Mitigation:
- App Group
- narrow shared model
- integration tests
- implement only after base persistence is stable

## Custom image storage

Imported files may disappear if only referenced externally.

Mitigation:
- copy into app-controlled storage

## Large libraries

Thousands of thumbnails can produce memory pressure.

Mitigation:
- lazy loading
- thumbnail sizing
- memory cache limits
- disk cache
- performance fixtures

## Over-designed UI

"Apple-like" can become fake glass and oversized cards.

Mitigation:
- use native controls first
- semantic colors
- restrained materials
- HIG-style hierarchy
- test with real content

---

# 48. RELEASE ACCEPTANCE TEST

Before first beta:

## Installation
- [ ] clean build
- [ ] fresh install
- [ ] first launch works

## Folder
- [ ] create
- [ ] rename
- [ ] reorder
- [ ] nest
- [ ] custom symbol
- [ ] custom imported icon
- [ ] delete/restore behavior

## Links
- [ ] add valid URL
- [ ] invalid URL
- [ ] duplicate URL
- [ ] metadata success
- [ ] metadata failure
- [ ] custom title
- [ ] custom icon
- [ ] custom thumbnail
- [ ] move
- [ ] multi-select
- [ ] favorite
- [ ] delete
- [ ] restore

## Preview
- [ ] hover
- [ ] rapid hover movement
- [ ] missing image
- [ ] offline
- [ ] cached content

## Search
- [ ] title
- [ ] host
- [ ] tag
- [ ] folder
- [ ] notes
- [ ] no result

## Widget
- [ ] widget appears in gallery
- [ ] configure folder
- [ ] shows correct links
- [ ] clicking link opens URL
- [ ] changes eventually refresh
- [ ] missing/deleted folder handled

## Appearance
- [ ] Light
- [ ] Dark
- [ ] small window
- [ ] large window
- [ ] Retina display

## Accessibility
- [ ] keyboard-only path
- [ ] VoiceOver labels
- [ ] reduced motion
- [ ] sufficient contrast

## Reliability
- [ ] app relaunch
- [ ] persistence survives relaunch
- [ ] corrupted/missing cached asset handled
- [ ] network unavailable
- [ ] no data loss after metadata failure

---

# 49. DEFINITION OF FIRST BETA

The first beta is ready when a user can:

```text
Install LinkShelf
   ↓
Create Development folder
   ↓
Give it a custom icon
   ↓
Save 10 links
   ↓
See metadata/thumbnails
   ↓
Hover for previews
   ↓
Drag links into folders
   ↓
Search instantly
   ↓
Favorite important links
   ↓
Add a Development widget to desktop
   ↓
Open saved links from the widget
```

and those flows are covered by the appropriate automated/manual tests.

---

# 50. RECOMMENDED STARTING COMMANDS

```bash
mkdir -p ~/PROJECTS
cd ~/PROJECTS

git config --global user.name "Geltrax69"
git config --global user.email "144154602+Geltrax69@users.noreply.github.com"

gh auth status

repo linkshelf-macos
```

Once the repository exists, create:

```text
README.md
PROJECT_TRACKER.md
DECISIONS.md
CHANGELOG.md
```

Then create/open the native macOS Xcode project.

After the first coherent scaffold:

```bash
repo linkshelf-macos
```

Commit:

```text
chore: scaffold native macOS app and test targets
```

---

# 51. FINAL BUILD PRINCIPLE

The project should optimize for this:

> **Native, useful, fast, organized, testable, and progressively shippable.**

Every feature should answer at least one of these questions:

- Does this make saving a link faster?
- Does this make finding a link faster?
- Does this make the library easier to understand?
- Does this make the app feel better integrated with macOS?
- Does this make the application safer to change?

If the answer is no, it probably does not belong in the first release.

---

# 52. OFFICIAL REFERENCES TO USE DURING IMPLEMENTATION

Prefer Apple's current documentation over copied snippets from old tutorials.

Relevant areas to consult:

- SwiftUI
- SwiftData
- WidgetKit
- App Intents
- LinkPresentation
- SF Symbols
- Human Interface Guidelines
- Swift Testing
- XCTest / XCUIAutomation
- App Sandbox
- App Groups
- UniformTypeIdentifiers
- NSWorkspace
- MenuBarExtra

When an API has changed in the currently installed Xcode version, use the compiler and current Apple documentation as the source of truth.

---

# 53. HANDOFF CHECKLIST FOR ANY AI CODING AGENT

Before changing code:

```text
[ ] Read PROJECT_TRACKER.md
[ ] Read DECISIONS.md
[ ] Check git status
[ ] Check recent commits
[ ] Identify current milestone
[ ] Run relevant tests
```

Before stopping:

```text
[ ] Build succeeds
[ ] Relevant tests pass
[ ] No accidental files staged
[ ] Tracker updated
[ ] Decisions documented
[ ] Change committed
[ ] Next task recorded
```

A future chat should be able to continue without relying on conversational memory.

The repository must explain its own current state.
