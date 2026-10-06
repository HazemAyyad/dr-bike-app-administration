# Online Store Listing Editor Design QA

- source visual truth path: `C:\Users\hp\.codex\generated_images\01a11118-e4f6-77c1-a1d3-a67e4cb0233d\exec-9c13ec83-a5af-4be8-b930-43d1824f35aa.png`
- implementation screenshot path: `test/goldens/online_store_listing_editor_ar.png`
- combined comparison: `test/goldens/online_store_listing_editor_comparison.png`
- viewport: 430 x 1800 logical pixels, devicePixelRatio 1
- source pixels: 887 x 1774; implementation pixels: 430 x 1800
- state: Arabic RTL, draft listing, custom name and description enabled, online limit 10, active category selected

## Full-view comparison evidence

The combined image confirms the same hierarchy and order: app bar and status, product summary, original/store-specific values, stock cards and limit control, media strip, category/visibility controls, readiness panel, and sticky actions. Neutral surfaces, thin borders, restrained purple accents, green readiness, and orange reserved-stock semantics match the source direction.

The production Flutter layout intentionally remains scrollable instead of compressing Arabic controls below accessible touch and text sizes. The reference is a tall concept render; the golden captures the complete scroll content for structural comparison.

## Focused fidelity surfaces

- Typography: Almarai is loaded in the golden; hierarchy, Arabic alignment, weights, and wrapping are consistent with the reference.
- Spacing and layout: 12-14 px card gaps/padding, rounded cards, two-column stock metrics, horizontal media, and sticky actions match. The production form is slightly more vertically breathable for accessibility.
- Colors: white/light-gray surfaces, dark text, purple selection/actions, green availability/readiness, and orange reservation match.
- Images and icons: production uses actual listing image URLs and Material icons. The deterministic golden fixture deliberately has empty image URLs; Material icon glyphs appear as fallback boxes in the headless golden environment, not in the built application (`uses-material-design: true`).
- Copy: visible Arabic labels and values match the approved mockup, with one additional safety explanation that the limit never changes base inventory.

## Findings

No actionable P0/P1/P2 implementation mismatch remains. The image/icon limitations above are test-fixture rendering limitations, not application UI behavior.

## Comparison history

1. Initial golden exposed an 8 px overflow in the long stock-mode row and missing Arabic glyphs.
2. The row label was made flexible and Almarai fonts were explicitly loaded.
3. The post-fix golden passed without overflow and was reviewed in the combined comparison.

## Follow-up polish

- P3: confirm real product crops and Material icon rendering on an attached device after the Laravel migration is applied.

final result: passed
