# Gavel — roadmap

## Product (north star)

> Gavel is a mock trial preparation app for student competitors that uses AI research and team collaboration tools to turn scattered case materials into a structured courtroom strategy.

In v1, AI features run on mock data behind repository and service interfaces. Later versions swap in Firebase (v2) and ChatGPT via Cloud Functions (v4). Detail for each version lives under [`docs/plans/`](docs/plans/).

## Guiding rules

- Small slices: one feature (or hardening) slice per iteration; tag when reviewable.
- **One page per file.** Feature-only widgets live in that feature’s `widgets/` folder. Shared UI goes in `lib/core/widgets/`.
- Pages talk to **repository/service interfaces**, not concrete backends. Mocks in v1; Firestore in v2; OpenAI adapters in v4.
- State: `provider` + `ChangeNotifier`. Navigation: `go_router` + `StatefulShellRoute` for the five tabs.
- Stable `ValueKey`s on interactive/asserted widgets.
- Tests mirror `lib/`. Every slice adds unit/widget coverage for what it touches.
- Agents use Flutter analysis, tests, and builds, plus emulator rules tests for Firestore changes. CI runs Playwright. Developers handle manual browser and device checks.

Pinned SDK: Flutter **3.50.0** / Dart **3.14.0** (`pubspec.lock`, CI). Workspace changes persist in the current browser profile when storage is available.

## Status

| Version | Status | Purpose |
|---|---|---|
| v0.1–v0.11 | **Complete** | Foundation through Welcome; see [v1-alpha.md](docs/plans/v1-alpha.md) and review notes below |
| v1.0 alpha | **Verified, tag pending** | Alpha features, screen-state audit, goldens, Chrome flow, and coverage |
| v2 | **In progress** | FlutterFire, Auth/invites, and Firestore reads and shared writes implemented; rollout and offline validation pending |
| v3 | **Planned** | iPhone + Android device validation (former Beta) |
| v4 | **Planned** | ChatGPT researcher / case brief via Cloud Functions (former “v3”) |
| v5 | **Planned** | Pre-launch extras; coach/judge, timer, iPad, later ideas |

## Agent routing

To work on a version, open **`@plan.md`** and the matching file under **`docs/plans/`**. Implement the next small slice from that file; do not pull unrelated versions into the same change.

| Version | Purpose | Path | Status |
|---|---|---|---|
| v0.1–v0.11 + v1.0 | Alpha completion record | [`docs/plans/v1-alpha.md`](docs/plans/v1-alpha.md) | Verified, tag pending |
| v2 | Firebase + Firestore | [`docs/plans/v2-firebase-firestore.md`](docs/plans/v2-firebase-firestore.md) | In progress |
| v3 | iPhone + Android device testing | [`docs/plans/v3-mobile-device-testing.md`](docs/plans/v3-mobile-device-testing.md) | Planned |
| v4 | ChatGPT LLM researcher / case brief | [`docs/plans/v4-chatgpt-llm.md`](docs/plans/v4-chatgpt-llm.md) | Planned |
| v5 | Pre-launch + future ideas | [`docs/plans/v5-prelaunch-and-future.md`](docs/plans/v5-prelaunch-and-future.md) | Planned |

How-to index: [`docs/plans/README.md`](docs/plans/README.md).

### Example prompts

```text
Review alpha release readiness using @docs/plans/v1-alpha.md.
```

```text
Build the next slice of @docs/plans/v2-firebase-firestore.md
Follow guiding rules in @plan.md.
Finalize / respect the bundle ID notes in that file.
Run Flutter analysis and tests, and the emulator rules tests if Firestore rules change.
```

```text
Build the next slice of @docs/plans/v3-mobile-device-testing.md
```

```text
Build the next slice of @docs/plans/v4-chatgpt-llm.md
```

**Ordering note:** Firebase (v2) comes before device Beta (v3). Finalize iOS bundle ID and Android `applicationId` early in v2 so FlutterFire and later device/push setup stay aligned. Details are in the v2 and v3 plan files.

## Review notes (completed milestones)

- [v0.5 review](docs/v0.5-review.md) · [UI redesign](docs/ui-redesign.md)
- [v0.6 review](docs/v0.6-review.md)
- [v0.7 review](docs/v0.7-review.md)
- [v0.8 review](docs/v0.8-review.md)
- [v0.9 review](docs/v0.9-review.md)
- [v0.10 review](docs/v0.10-review.md)
- [Project handoff](docs/PROJECT-HANDOFF.md)
