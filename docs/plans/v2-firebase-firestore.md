# v2 — Firebase and Firestore

**Status:** Precursor complete and bootstrap in progress

**Purpose:** Accounts, shared team data, real-time sync, storage, and notifications.

Root roadmap: [`plan.md`](../../plan.md).

## Goal

Replace browser-local mock data with Firebase so teammates share cases, tasks, chat, and readiness in real time, with Auth, Storage, security rules, and FCM.

## Non-goals

- No live ChatGPT / OpenAI (v4). Keep `ResearchService` / `CaseBriefService` mocks until then, or leave stubs behind the same interfaces.
- No full hardware release gate (v3). CI unsigned iOS build continues; physical device smoke is v3.
- No coach/judge/scrimmage product expansions (v5).

## Prerequisites

- v1.0 alpha finishing or complete: stable repository/service interfaces and `toMap`/`fromMap` shapes.
- **Finalize bundle ID / `applicationId` early in this version** (or immediately before `flutterfire configure`). Placeholder `com.example.gavel` must become something unique (for example `com.<team>.gavel`) on iOS and Android together. Changing it after Firebase config is painful for v2↔v3.
- Firebase project access; FlutterFire CLI available.
- iOS deployment target remains 15.0+ (meets Firebase minimum).

## Bootstrap progress

- [x] Installed and verified Firebase CLI 15.36.0 and FlutterFire CLI 1.5.0.
- [x] Added and locked the Core, Auth, Cloud Firestore, and Storage Flutter plugins.
- [x] Set the iOS and Android app display name to Gavel.
- [ ] Sign in with `firebase login` and select the Firebase project.
- [ ] Confirm the permanent app ID and apply it to the iOS Runner and Android app before registering either platform.
- [ ] Run FlutterFire configure for iOS, Android, and web, then initialize Firebase with the generated options.

FlutterFire is installed in the Dart pub cache. With Flutter 3.50.0 on PATH,
use the following command after confirming the project and mobile app ID.

```sh
dart pub global run flutterfire_cli:flutterfire configure \
  --project=PROJECT_ID --platforms=ios,android,web
```

## Architecture / swap-in strategy

v1 already routes UI → controllers → **interfaces** → mocks. v2 adds implementations that satisfy those interfaces:

- Add `Firestore*Repository` (and Auth-backed session) using streams for live updates.
- Wire providers to Firestore impls in production; keep mocks for unit tests and local demos.
- Turn on Firestore offline persistence for practice rooms with poor signal.
- Team chat, task queues, and readiness sync across teammates’ devices.

### Data model (maps from v1 `toMap`/`fromMap`)

- `teams/{teamId}` with subcollections `members`, `cases/{caseId}`, `tasks`, `sessions`, `chat`
- `cases/{caseId}` with subcollections `exhibits`, `witnesses`, `affidavits`, `brief`, `exam_scripts`, `sources`

### Auth model

- Email or Google sign-in, plus Sign in with Apple (App Store rule when other social logins are offered).
- Users join a team with an invite code.
- This replaces the local `onboarded` flag.

## Ordered iterations

Suggested tags: `v2.1`, `v2.2`, … (or keep working on a `v2` branch until a release tag).

1. **Bundle ID + FlutterFire bootstrap**  
   Set iOS bundle ID and Android `applicationId` to the final value; display name "Gavel". Run `flutterfire configure` for iOS, Android, and web. Add `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`. Add `GoogleService-Info.plist` via FlutterFire on iOS.

2. **Auth + team invite**  
   Sign-in flows; invite code joins a team; session controller uses Firebase Auth instead of local onboarded-only state.

3. **Firestore repositories (read path)**  
   Implement case, team, task, schedule, chat read/streams against the collections above; seed or migrate demo State v. Harmon for one team.

4. **Write path + real-time UX**  
   Assignments, tasks, chat sends, and readiness update live for other members; offline persistence on.

5. **Storage**  
   Upload case packet PDFs and exhibit images to Firebase Storage; link from case models.

6. **Security rules**  
   Only team members read/write their team; only captain/coach assign roles. Test with Firebase Emulator Suite.

7. **Notifications (FCM)**  
   “You were assigned a role”, new chat messages, practice reminders. iOS: APNs key + push capability in Xcode (device delivery verified in v3).

## Done checklist (per slice)

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (fakes/mocks for Firebase where needed)
- [ ] Manual smoke in Edge/Chrome for web Auth/data paths touched by the slice
- [ ] Emulator or rules tests updated when rules/repos change
- [ ] Commit; tag when the slice is reviewable

## Testing notes

- Unit tests: `fake_cloud_firestore`, `firebase_auth_mocks` (or project equivalents).
- CI: run integration tests against Firebase emulators when added.
- Do not put secrets in the repo; use FlutterFire / CI secrets for config that must not be committed.

## Risks / ordering notes (v2 ↔ v3)

- **Bundle ID first.** Finalize iOS bundle ID and Android `applicationId` before or in slice 1. v3 device installs and push certs assume that ID is stable.
- Original plan put device Beta before Firebase for this reason; the roadmap now does Firebase next, so the ID work moves into v2 prerequisites/slice 1 instead of waiting for v3.
- Avoid changing application IDs between FlutterFire configure (v2) and App Store / Play device testing (v3).
- FCM on iOS needs APNs; configure in v2, validate on a physical iPhone in v3.
- Keep OpenAI keys out of the client; LLM work stays in v4 behind Cloud Functions.
