# Editorial workspace redesign

## Design system

- Warm paper `#F8F6F1`, charcoal `#292421`, burgundy `#641F32`, and muted warm-gray secondary text.
- Bundled Fraunces for editorial headings; Inter for controls, metadata, and body text. No new dependencies or remote fonts.
- Shared spacing, 10px control/card corners, 16px dialog corners, and restrained surfaces. Lists use whitespace rather than repeated bordered cards.
- Shared `WorkspacePage`, `WorkspaceScrollView`, and `WorkspaceColumns` components. Content is capped at 1120px; the affidavit reader is capped at 680px.
- Existing Light, Dark, and Midnight themes remain available. Small status text uses readable colors, with adjusted colors in dark themes.

## Navigation and layout

Phones retain Home, Case, AI, Team, and Profile in an integrated bottom bar, inside the scaffold layout and above the home-indicator safe area. Controls have consistent outlined icons, text labels, keyboard focus, and active-state indicators. Larger text increases the bottom bar's height.

At 760px, global navigation moves to a compact sidebar; at 1100px it expands. The sidebar fills the window height and scrolls in short windows. The Home dashboard and Case overview/brief use separate columns when enough content width is available. Affidavits form a two-column list when the available content width reaches 600px.

The Case page has an editorial case title, understated date/countdown, compact record counts, and horizontal tabs. More stays visible at the trailing edge; primary tabs can scroll without wrapping. Exhibits is a primary tab at wider content widths and is available through More on phones; Stipulations and Rules remain in More.

## Affidavit reading

Witness entries show the original name, role, side, and a two-line excerpt of the original statement. Search matches names, roles, and statement text, and combines with a prosecution/defense filter. A reset action restores all results.

Selecting an entry opens `/case/affidavit/:id` within the existing Case navigation branch. The original statement is selectable and displayed at 18px with 1.85 line height. Back navigation preserves the list's search/filter state and scroll position. Brief links to affidavits use the same reader; exhibit links retain their source dialog. Direct reader URLs and unavailable IDs have explicit behavior.

All existing route paths remain available. Case materials, repository interfaces, controllers, countdown math, task/readiness logic, and seed records were left unchanged by the redesign. AI, Team, and Profile retain their existing feature availability; no simulated working features were added.

## Verification

The full suite contains 81 passing tests. Coverage includes:

- Case sections and all evidence links, along with existing model, controller, and repository tests.
- Layouts at 320×780, 390×844, 834×1112, and 1440×1000, including every global destination.
- Two-column witness layouts, bounded reader width, and two-line preview constraints.
- Search plus side filtering, reset, reader back navigation, direct URLs, and unavailable records.
- Keyboard activation of witness entries and More-menu sections.
- Mobile navigation/content separation, home-indicator safe area, and all Case sections at 2× text.
- All three themes at phone width with enlarged text, plus text contrast for the light palette.

`flutter analyze --no-pub` is clean, and `flutter build web --no-pub` succeeds
(including the Wasm dry-run check). The production bundle is in `build/web`.
Widget-rendered inspection images can be regenerated with:

```sh
flutter test --no-pub test/design/workspace_layout_test.dart --dart-define=GAVEL_CAPTURE=true
```

This optional command writes inspection PNGs to `/private/tmp/gavel-redesign`; normal test runs do not write images. It uses the bundled typefaces and Material icon font.

## Manual browser review

The repository rule `.cursor/rules/no-agent-ui-testing.mdc` reserves browser checks for developers. Automated widget layouts were rendered and inspected; no local server or browser was started by the agent.

1. Run `flutter run -d chrome`. Review Case and Home at phone, tablet, and desktop widths; confirm the bottom bar becomes a sidebar and content stays clear of navigation.
2. In Case → Affidavits, search, filter by side, open a witness, select the text, and return. Confirm the original text and your prior filter/scroll position.
3. Use Tab and Enter to navigate tabs, More, witness entries, and global destinations. Try enlarged browser text and the Dark/Midnight themes.

The earlier logical/product findings remain recorded, unfixed, in `v0.5-review.md`.
