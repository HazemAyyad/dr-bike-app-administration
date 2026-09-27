# Doctor Bike Home correction QA

- Source visual truth: `C:\Users\hp\Downloads\ChatGPT Image Sep 27, 2026, 01_39_57 PM.png`
- Source pixels: `941 x 1672`
- Pre-fix real-device implementation: `C:\Users\hp\Downloads\ChatGPT Image Sep 27, 2026, 09_00_08 PM.jpg`
- Pre-fix implementation pixels: `691 x 1536`
- Post-fix implementation screenshot: not captured
- State: authenticated admin Home, light mode, populated production dashboard data
- Viewport/density normalization: the two supplied images have different pixel densities and device chrome; comparison was limited to content hierarchy, wrapping, spacing, and overlap rather than pixel measurements.

## Full-view comparison evidence

The supplied real-device screenshot confirmed four actionable differences from the approved source: the attention card was absent, the header-to-overview gap was excessive, the first two overview titles wrapped poorly, and the centered FAB sat over the All Sections grid instead of the navigation edge. The corrected Flutter build has not yet been rendered on the same device, so post-fix visual closure is blocked.

## Focused-region comparison evidence

- Header/attention/overview: the pre-fix screenshot shows no attention card even though the same API badge map visibly reports suspended sales and undelivered maintenance counts.
- Overview cards: `لنا (مستحقات)` and `علينا (التزامات)` wrap across narrow cards; the corrected source uses the approved short titles `لنا` and `علينا` and retains the single-row grid and fitted one-line values.
- Bottom region: the pre-fix screenshot shows the FAB above the navigation surface and over a card. The corrected source docks the finite FAB to the outer navigation Scaffold and reserves content clearance from its measured diameter.

## Required fidelity surfaces

- Fonts and typography: existing application typography is preserved; only the two KPI titles were shortened. Post-fix wrapping requires device confirmation.
- Spacing and layout rhythm: existing card/grid dimensions are preserved. Header-to-content spacing is reduced through a dashboard token, and bottom clearance is derived from half the centered FAB diameter plus normal section spacing.
- Colors and visual tokens: unchanged from the approved dashboard palette.
- Image quality and asset fidelity: no images or assets changed.
- Copy and content: new attention labels use the exact existing counter semantics: suspended sales and maintenance records not yet delivered. No screenshot counts are hardcoded.

## Findings

- [P1] Post-fix device capture is unavailable.
  - Location: admin Home on the supplied Android device width.
  - Evidence: the pre-fix device screenshot and approved source were compared together, but there is no rendered screenshot after this correction.
  - Impact: final FAB docking, narrow KPI fit, attention-card height, RTL chip wrapping, and last-row clearance cannot be visually proven.
  - Fix: hot-reload or launch the corrected build on the same device, capture the Home at the top and at maximum scroll, and verify the expanded search and FAB menu states.

## Comparison history

- Iteration 1: supplied pre-fix screenshot exposed the missing attention card, excessive upper gap, KPI title wrapping, and FAB/card overlap.
- Fixes applied: consume the existing `sales` and `maintenance` badge keys, stop a saved visibility flag from suppressing real actionable alerts, shorten KPI titles, reduce tokenized header spacing, move the FAB to the outer navigation Scaffold, and calculate bottom content clearance from FAB size.
- Post-fix visual evidence: pending a real-device screenshot.

## Primary interactions pending device verification

- Attention card/chips after asynchronous API loading and pull-to-refresh.
- Search expand/filter/clear/collapse.
- Shortcut customization and saved order.
- FAB menu open/close and navigation.
- Bottom navigation, dark mode, RTL overflow, and final-row scrolling above the docked FAB.

## Static checks

- Targeted Flutter analysis: passed with no issues.
- Full-project Flutter analysis: completed with 107 pre-existing warnings/info findings outside the six modified Dart files; the targeted analysis for all modified Dart files passed with no issues.
- Runtime/device log: not captured in this correction run.

final result: blocked
