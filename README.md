# Gavel · v0.8 alpha

An editorial workspace for mock trial preparation, built with Flutter. The alpha
contains Home, the six-section Case workspace, a source-linked Research hub,
the Team roster and role assignment workflow, Profile checklists, Practice Schedule,
and the shared navigation/design system. Examinations and team chat remain future milestones in [plan.md](plan.md).

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

## Profile and Practice Schedule in v0.8

Profile shows the demo teammate, assigned/complete/remaining task counts, a
personal completion bar and a checkbox checklist. Completion changes are saved
through TaskRepository, update Home and Team, and can be reversed. Role
responsibility task completion survives controller reloads in the same session.
A failed save keeps the previous checkbox value and offers retry.

Quick access opens Schedule, Case, Research, Team and the existing theme gallery.
Practice Schedule includes a trial countdown, previous/next week controls, a
Monday–Sunday day strip, upcoming/ongoing personal sessions and a weekly planning
goal. The goal counts scheduled minutes for the entire selected week, including
earlier sessions; selecting a day only filters the list. It does not measure
attendance. Times use the device's local time. The sample goal is 180 minutes.

Schedules are read-only; task completion and assignments last only for the app
session. Reloading resets the demo data. No backend or notification service is
connected.

## Team in v0.7

Team separates role coverage from task completion. Filter prosecution/defense sides, each with attorney and witness groups, open a role, review its responsibilities, select
a teammate, and assign it. Each responsibility becomes an unfinished task due on
the demo trial date. Home and Team share the updated completion percentage.
Expand a roster member to inspect their task queue.

Suggestions use a deterministic workload ranking (fewest unfinished tasks, then
name and ID), not live AI or inferred skills. Multiple roles per teammate are
allowed; users must review trial scheduling and conflicts. Filled roles are
read-only in this slice. Assignments and their tasks are session-only, and no
team notification is sent. Team chat remains a v0.10 milestone.

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

- **v0.7:** Team roster, trial roles, workload suggestions, atomic local role
  assignments and responsibility task queues.

- **v0.8:** Profile checklists, shared task completion, quick access, and a
  personal practice schedule with day/week filtering and weekly planning goals.

See [v0.8 notes](docs/v0.8-review.md), [v0.7 notes](docs/v0.7-review.md), [v0.6 notes](docs/v0.6-review.md), the
[original review](docs/v0.5-review.md), and the
[design notes](docs/ui-redesign.md). Release tags are created after the manual
smoke test; the version in `pubspec.yaml` describes the implemented feature slice.
