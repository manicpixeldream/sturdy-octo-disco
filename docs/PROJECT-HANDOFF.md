# Gavel project handoff

Gavel is a Flutter web alpha for student mock trial teams. It brings case materials, research, roles, tasks, practice, examination scripts, and team chat into one workspace.

- [Original plan at commit 4c752df](https://github.com/manicpixeldream/sturdy-octo-disco/blob/4c752df4ba43362a4bc620d03f4be09930c394ef/plan.md)
- [Current plan](../plan.md) and [README](../README.md)

## Work completed, in order

| Milestone | Changes | Verification recorded |
|---|---|---|
| v0.1–v0.4 | Starting foundation: themes, navigation, immutable models, mock repositories, Home dashboard, and task progress. | Existing foundation on main. |
| [v0.5](v0.5-review.md) | Built the six-section Case workspace: Overview, Brief, Affidavits, Exhibits, Stipulations, and Rules. Added evidence links, searchable witness previews, and a dedicated affidavit reader. Reviewed workflow inconsistencies before fixing them in later milestones. | See milestone review and [redesign notes](ui-redesign.md). |
| [v0.6](v0.6-review.md) | Added Research Ask and Library, prepared cited answers, searchable and saved sources, source details, and citation backlinks. Added retry states and live date-label refresh, disclosed launch-relative demo dates, aligned CI and SDK settings, and corrected the readiness and timing requirements in the roadmap. | 117 tests, analysis, and web build passed. |
| [v0.7](v0.7-review.md) | Added Team roster, role detail and assignment, workload-ranked suggestions, and shared responsibility tasks. Kept role coverage distinct from task completion. Refined role cards, teammate borders, and side/status alignment; grouped witnesses under Prosecution and Defense. | 130 tests and analysis passed after refinements. |
| [v0.8](v0.8-review.md) | Added Profile checklists, stats, and quick access. Completion updates Home and Team and survives controller reloads in the same session. Added Practice Schedule with day/week filters and a weekly goal for planned minutes. | 153 tests and analysis passed. |
| Countdown refinement | Made the trial countdown easier to spot on Home, Case, and Schedule, then reduced the badge size, removed the calendar icon, and used a subtle tint and border. | 153 tests and analysis passed. |
| [v0.9](v0.9-review.md) | Added separate Direct and Cross scripts and goals for each witness, question editing, reordering, deletion, review flags, exhibit links, and prepared suggestions. Research links back to the exact question. Timing checks aggregate scripts by examining side and phase across witnesses. | 175 tests and analysis passed. |
| [v0.10](v0.10-review.md) | Added local Team Chat, timestamps, keyboard sending, and a searchable picker for up to five task or exhibit links. Task mentions open task details; exhibit mentions open the source reader. Failed sends keep the draft; unchanged retries reuse the message ID. | 196 tests and analysis passed. |
| v0.11 | Added first-visit Welcome and connected Home assignments, examination research, draft review, Team Chat, and practice agendas. | Covered by onboarding and prep workflow tests. |
| Browser persistence and SDK upgrade | Persisted workspace changes in browser storage and moved development and CI to Flutter 3.50.0 and Dart 3.14.0. | Persistence tests, static analysis, web build, and unsigned iOS build passed. |
| v1.0 accessibility checks | Added phone-width checks for 14 routes at 1.3× text and fixed an overflow in the Research header. | Static analysis and 238 tests passed. Line coverage was 99.1% for state and 92.2% for data. |

## Design and implementation

- Editorial design: cream, charcoal and burgundy, bundled Fraunces and Inter, and existing Light, Dark, and Midnight themes.
- Shared responsive shell: bottom navigation on phones, sidebar on wider screens, and separate Case tabs. Home, Case, Research, Team, and Profile remain accessible.
- Provider and ChangeNotifier manage state; go_router handles routes. Repository and service interfaces keep demo data separate from screens.
- The fictional State v. Harmon packet has 14 exhibit descriptions, six witnesses and affidavits, stipulations, a mock brief, and timing rules. No original exhibit files are attached.
- The demo trial date is 23 days from the first visit. Workspace changes, including opening and closing drafts, survive reloads when storage is available for the same site and browser profile. AI responses and suggestions are prepared demos. Schedule goals measure planned minutes.

## Git and preview

- Repository: [manicpixeldream/sturdy-octo-disco](https://github.com/manicpixeldream/sturdy-octo-disco).
- Published milestones: v0.5 `3aba191`, v0.6 `97f92a4`, v0.7–v0.8 `74fbd9f`, and countdown refinement `079346e`.
- Commit `5892c93` connects assignments, research, review, and practice. Use `git status` to check for ongoing local edits.

## Run and verify

Use Flutter 3.50.0 and Dart 3.14.0, matching CI. From the repository root:

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome --dart-define=GAVEL_DEMO=true
flutter analyze
flutter test
```

CI also runs a web build and checks an unsigned iOS build. Developers run the browser smoke checks below. The unsigned iOS build on Flutter 3.50.0 passed from a clean temporary copy.

1. Check Home and Case at phone and desktop widths. Open an affidavit and its Direct or Cross builder.
2. Edit questions, link an exhibit, and follow its Research backlink. Exceed a shared timing limit across two witnesses on the same examining side.
3. Assign a Team role, check off one of its tasks in Profile, and compare progress on Home and Team. Change the selected practice day and week.
4. Open Team Chat, send a task and exhibit reference, and open both. Check the composer with larger text, the keyboard open, and Midnight enabled.
5. Reload on the same site and browser profile. Confirm Welcome stays dismissed and the drafts, messages, and task and agenda changes are still available.

## Next steps

Use the root [plan.md](../plan.md) agent routing table. Detailed plans live under [docs/plans/](plans/).

1. Tag the verified web alpha when ready to publish. The [alpha completion record](plans/v1-alpha.md) captures the hosted checks.
2. Continue [v2 Firebase / Firestore](plans/v2-firebase-firestore.md) with the Firestore read path after Firebase setup and Auth smoke.
3. v3 iPhone + Android device testing (former Beta): [plans/v3-mobile-device-testing.md](plans/v3-mobile-device-testing.md).
4. v4 ChatGPT LLM (former plan “v3”): [plans/v4-chatgpt-llm.md](plans/v4-chatgpt-llm.md).
5. v5 pre-launch / later ideas: [plans/v5-prelaunch-and-future.md](plans/v5-prelaunch-and-future.md).
