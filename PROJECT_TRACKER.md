# LinkShelf Project Tracker

## Current Milestone
M0 → M1 — Engineering documentation and native application shell.

The blueprint's FIRST TASK explicitly ends this session after the shell builds and tests. Later milestones must remain separate vertical slices.

## Completed
- [x] Read the product blueprint and inspect the empty project directory.
- [x] Verify Xcode 26.3, Swift 6.2.4, and XcodeGen availability.
- [x] Create engineering documentation and milestone checklist.

## In Progress
- [ ] M1: Xcode app, unit test, and UI test targets.
- [ ] Native navigation shell and contextual empty states.
- [ ] Build, automated tests, and appearance verification.

## Next
- [ ] M2: Extend the design system and navigation as real features arrive.
- [ ] M3: SwiftData folders, validation, nested-folder cycle rules, icon model and imports.
- [ ] M4: Link creation, editing, deletion and persistence.
- [ ] M5: Safe URL normalization and explicit duplicate handling.
- [ ] M6: Metadata provider and bounded asset cache.
- [ ] M7: Visual cards and cancellable hover previews.
- [ ] M8: Drag/drop, folder organization and sorting.
- [ ] M9: Deterministic search, favorites and recents.
- [ ] M10: Widget extension, shared App Group snapshots and folder configuration.
- [ ] M11: Menu bar and keyboard productivity.
- [ ] M12: Accessibility, performance and error handling.
- [ ] M13: Full regression and UI tests.
- [ ] M14: Beta packaging and release documentation.

## Blockers
None for local development. A signing team and App Group provisioning will be needed for distributable widgets in M10.

## Known Bugs
No implementation exists yet. Planned features are not completed functionality.

## Test Status
Toolchain health check: PASS. Application tests: not yet created/run.

## Important Files
- `LinkShelf_macOS_Project_Blueprint.md` — original requirements, preserved.
- `project.yml` — forthcoming reproducible Xcode target definitions.
- `Docs/architecture.md` and `Docs/testing.md` — engineering boundaries and verification.

## Last Commit
Initial documentation commit pending. Use `git log -1` for the authoritative commit after each recorded update.

## Next Recommended Commit
`chore: scaffold native macOS app and test targets`
