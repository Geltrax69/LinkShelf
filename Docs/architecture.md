# Architecture

LinkShelf is a local-first native macOS application. The initial shell owns window composition, library destinations, settings, and navigation commands. It does not create a pretend database or start network requests.

Feature views live under `LinkShelf/Features`; app composition and commands under `LinkShelf/App`; shared spacing and sizing under `LinkShelf/DesignSystem`. Keep pure navigation values testable without UI automation.

Next: add domain models and repository boundaries only as SwiftData folders and links need them. Metadata and file storage will use effect protocols and asynchronous implementations. Persist imported images inside controlled storage, preserving only asset identifiers in models. The widget will consume minimal shared snapshots after persistence is verified.

Source of truth: `project.yml` for target settings, the blueprint for product scope, and `PROJECT_TRACKER.md` for actual completion.
