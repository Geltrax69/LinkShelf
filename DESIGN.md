# LinkShelf Design System

## Authority
The supplied blueprint pins the visual direction: a native Mac productivity utility with a NavigationSplitView sidebar, system toolbar, contextual main content and optional future inspector. This is an implementation of that direction, not a new visual identity exercise.

## Library surface
Mode: Operate. People scan and revisit saved resources while working alongside their browser. Respect the user's system appearance in bright and dim environments.

Use the system font and semantic foreground/background colors. Reserve the accent for selection and meaningful actions. Use SF Symbols consistently. Standard native List rows, toolbar controls, sheets and settings own interaction behavior. The initial shell uses generous empty-state spacing and compact sidebar rows; it does not introduce placeholder link cards.

## Layout and states
Default window: 1040 × 700 points; minimum 720 × 480. Sidebar: 180–280 points. Central content adapts to available width. Contextual empty copy distinguishes all library destinations. Build-stage details live in a sheet, reached through a clearly named information button. Future add/edit actions appear only when implemented.

## Tokens
Spacing: 4, 8, 12, 16, 24, 32 points. Use semantic type styles and the native control sizes. No custom title bar, decorative animation, or repeated shadows. The sidebar and content should remain legible under both system appearances.
