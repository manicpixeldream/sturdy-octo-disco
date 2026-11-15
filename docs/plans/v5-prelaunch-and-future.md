# v5 — Pre-launch extras and later ideas

**Status:** Planned  
**Purpose:** Extra iterations before a broader launch, plus longer-horizon product ideas from the original roadmap.

Root roadmap: [`plan.md`](../../plan.md).  
This absorbs the former **Later ideas** section and leaves room for pre-launch hardening after v2–v4.

## Goal

Close gaps that block a serious school/team launch (polish, roles beyond student competitors, practice tooling) without rewriting the v1–v4 architecture.

## Non-goals

- Not a dump of unfinished v2–v4 work — finish those plans first.
- Not a second product vision; stay inside mock trial prep for student teams (and adjacent coach/judge flows listed below).

## Prerequisites

- v2 persistence and Auth in place for any multi-user or role-based feature.
- v3 device validation for anything that ships to the App Store / Play.
- v4 LLM paths stable if a feature depends on live research or brief parsing.

## Architecture / swap-in strategy

Continue the same pattern: pages → controllers → repository/service interfaces → Firebase (and Cloud Functions where AI is required). Prefer new feature folders under `lib/features/` and matching `test/` trees. Reuse core widgets and design tokens.

## Ordered iterations (suggested; refine when scheduling)

Pre-launch slices (taggable as `v5.1`, …):

1. **Launch readiness pass** — production Firebase projects, store listings, privacy copy, crash/analytics as needed, final empty/error polish on phone and web.
2. **Coach view** — read-oriented roster, assignment oversight, and practice progress without turning the coach into a second full student workspace.
3. **Judge / ballot tooling** — scrimmage scoring with ballots aligned to common mock trial ballot categories.
4. **Timer mode** — live practice timer tied to existing timing rules (opening, direct, cross, closing).
5. **iPad / large-tablet layout** — adapt the existing responsive shell for courtroom-table use, without a separate app.

Longer-horizon ideas from the original plan (schedule only after the above earns its keep):

- Deeper multi-case team libraries
- Richer notification preferences
- Export of scripts/ballots for coaches

## Done checklist (per slice)

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Manual smoke on web; on iPhone/Android when the slice is mobile-facing
- [ ] New screens follow one-page-per-file and ValueKey rules from [`plan.md`](../../plan.md)
- [ ] Commit; tag when the slice is reviewable

## Testing notes

- Widget tests for new pages; unit tests for scoring/timer math.
- If a slice uses Firestore or Functions, extend emulator coverage from v2/v4 patterns.
- Keep golden or large-text checks when adding major layouts (especially iPad).

## Risks / ordering notes

- Do not start coach/judge/timer work on mocks alone if launch needs shared data — land v2 first.
- Timer and ballot UX should respect the same timing rules model from v0.5 / Examination Builder.
- Avoid bloating the five-tab student shell; coach/judge may be separate entry routes or roles.
- Bundle ID and push certs remain owned by v2/v3; v5 should not renumber application IDs casually.
