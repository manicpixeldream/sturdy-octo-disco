# Gavel · v0.6 alpha

An editorial workspace for mock trial preparation, built with Flutter. The alpha
contains Home, the six-section Case workspace, a source-linked Research hub,
and the shared navigation/design system. Team roles, personal task editing,
schedules, examinations, and team chat remain future milestones in [plan.md](plan.md).

## Run locally

Use **Flutter 3.47.2 / Dart 3.13.2**, matching `.github/workflows/ci.yml`.
Dependencies are pinned in the committed `pubspec.lock`.

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
```

The UI supports phone, tablet, and desktop widths. Global navigation changes
from a bottom bar to a sidebar on wider screens. The bundled Fraunces and Inter
fonts work without a font service.

## Research in v0.6

- **Ask:** use a suggestion or enter a question. Responses are prepared,
  keyword-matched demonstrations with numbered points and citations. They are
  not live AI or live web research.
- **Library:** browse the source catalogue, save references, and search saved
  sources by title/citation. Saves and chat history last for the app session;
  reloading clears them.
- **Sources:** read the source summary or original sample packet text, copy an
  official reference URL, and follow actual “Cited in” entries back to a Research
  answer or Case brief fact. Saving a reference does not claim it was cited.
- Reference summaries identify their federal/historical scope. They are not
  assumed to govern the fictional state case or a competition's rulebook.

## Demo data and dates

State v. Harmon is a fictional training packet: 14 exhibit descriptions, six
witnesses, six sample affidavits, stipulations, a mock brief, and timing rules.
There are no original exhibit PDFs or images attached. Research references are
separate from case facts; the case materials have not been rewritten.

The demo schedule intentionally resets on each launch: the trial is 23 days from
launch and task deadlines are relative to that day. Home and Case label this
behavior. While the app stays open, calendar labels refresh as time advances
and when the app resumes. Real, persistent dates and shared accounts are future
backend work.

## Verification

```sh
flutter analyze
flutter test
flutter build web
```

CI analyzes/tests/builds the web app on Ubuntu and checks an unsigned iOS build
on macOS. Browser smoke tests are performed by developers, per
`.cursor/rules/no-agent-ui-testing.mdc`.

## Versions and notes

- **v0.1–v0.4:** themes, global navigation, immutable models/mock repositories,
  Home, and task-based preparation completion.
- **v0.5:** Case workspace, evidence-linked mock brief, sample affidavits and
  timing rules, followed by the editorial UI redesign and affidavit reader.
- **v0.6:** Ask/Library, source details, saving and citation tracking, plus
  repository error recovery, date-label refresh, explicit demo date behavior,
  aligned SDK configuration, and updated release documentation.

See [v0.6 notes](docs/v0.6-review.md), the
[original review](docs/v0.5-review.md), and the
[design notes](docs/ui-redesign.md). Release tags are created after the manual
smoke test; the version in `pubspec.yaml` describes the implemented feature slice.
