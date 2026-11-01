# Design and iteration guide

## Design the task, not a generic landing page

- Put the working experience first unless the user explicitly requests a marketing/landing page.
- Match information density to the job. Operational tools should support scanning, comparison, filtering, and repeated actions; creative tools can be more expressive.
- Use the project's existing design system and brand assets where available. A supplied screenshot is a reference for specified details, not permission to copy unrelated branding.
- Avoid oversized hero sections, decorative card-heavy composition, and gratuitous gradients in tools that need to be efficient.
- Use consistent spacing, clear hierarchy, stable control dimensions, readable text, appropriate icons, and clear action labels.
- Keep page-level horizontal scrolling out of normal form/filter layouts. A wide data table may scroll within its own container if needed.
- Respect system light/dark preferences when supported by the stack.
- Aim for WCAG AA contrast, semantic markup, keyboard access, visible focus, appropriate labels, and text resizing without broken layouts.

These are defaults, not inflexible art direction. User requirements, reference material, an existing product style, or an appropriate specialist design system take precedence.

## Short iteration loop

1. Build one complete user journey.
2. Run the application and inspect the result in a browser when possible.
3. Compare behavior and layout to the brief and reference material.
4. Make a focused set of changes while preserving working behavior and data.
5. Re-run the affected tests and inspect for regressions.
6. Summarize changes and any unverified areas before taking the next request.

When providing a preview, say whether it is development-only and which interface/port it uses. Do not suggest that a local preview is publicly available.

## Visual acceptance checks

- Main action is obvious without unnecessary scrolling.
- Labels, values, and controls fit on narrow screens.
- Empty, loading, success, error, and validation states fit the design.
- Focus, keyboard behavior, contrast, and text scaling are usable.
- Layout does not shift unexpectedly as content, hover state, or button text changes.
- Real data and sample data are clearly distinguished.
- No decorative style compromises the task's clarity or accessibility.
