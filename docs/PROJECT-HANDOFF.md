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

## Design and implementation

- Editorial design: cream, charcoal and burgundy, bundled Fraunces and Inter, and existing Light, Dark, and Midnight themes.
- Shared responsive shell: bottom navigation on phones, sidebar on wider screens, and separate Case tabs. Home, Case, Research, Team, and Profile remain accessible.
- Provider and ChangeNotifier manage state; go_router handles routes. Repository and service interfaces keep demo data separate from screens.
- The fictional State v. Harmon packet has 14 exhibit descriptions, six witnesses and affidavits, stipulations, a mock brief, and timing rules. No original exhibit files are attached.
- The trial date starts 23 days from launch. Work is session-only, including the opening and closing drafts in Case → More → Arguments. AI responses and suggestions are prepared demos. Team Chat does not deliver real messages or notifications. Schedule goals measure planning rather than attendance.

## Git and preview

- Repository: [manicpixeldream/sturdy-octo-disco](https://github.com/manicpixeldream/sturdy-octo-disco).
- Published milestones: v0.5 `3aba191`, v0.6 `97f92a4`, v0.7–v0.8 `74fbd9f`, and countdown refinement `079346e`.
- Local main and the last fetched origin/main point to `079346e`. The local `codex/v0.10-team-chat` branch contains the v0.9 and v0.10 work.
- VS Code was opened for the project and a Flutter Chrome preview was started with hot reload. The preview was restarted after adding the examination and chat providers. Check whether that session is still active before relying on it.

## Run and verify

Use Flutter 3.47.2 and Dart 3.13.2, matching CI. From the repository root:

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
flutter analyze
flutter test
```

CI also runs a web build and checks an unsigned iOS build. Manual browser checks are performed by developers. After the audit fixes, analysis, all 200 tests, and the web build passed. The unsigned iOS build passed from a clean temporary copy after the build in the working directory failed on framework file metadata.

1. Check Home and Case at phone and desktop widths. Open an affidavit and its Direct or Cross builder.
2. Edit questions, link an exhibit, and follow its Research backlink. Exceed a shared timing limit across two witnesses on the same examining side.
3. Assign a Team role, check off one of its tasks in Profile, and compare progress on Home and Team. Change the selected practice day and week.
4. Open Team Chat, send a task and exhibit reference, and open both. Check the composer with larger text, the keyboard open, and Midnight enabled.
5. Reload and confirm that session-only changes reset as described.

## Next steps

Use the root [plan.md](../plan.md) agent routing table. Detailed plans live under [docs/plans/](plans/).

1. Finish v1.0 alpha polish: [plans/v1-alpha.md](plans/v1-alpha.md).
2. v2 Firebase / Firestore: [plans/v2-firebase-firestore.md](plans/v2-firebase-firestore.md) (finalize bundle ID early).
3. v3 iPhone + Android device testing (former Beta): [plans/v3-mobile-device-testing.md](plans/v3-mobile-device-testing.md).
4. v4 ChatGPT LLM (former plan “v3”): [plans/v4-chatgpt-llm.md](plans/v4-chatgpt-llm.md).
5. v5 pre-launch / later ideas: [plans/v5-prelaunch-and-future.md](plans/v5-prelaunch-and-future.md).
