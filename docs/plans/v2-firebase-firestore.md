# v2 — Firebase and Firestore

**Status:** FlutterFire bootstrap and email Auth + team invites are implemented. Firebase setup and browser smoke are pending. The next implementation slice is the Firestore read path.

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
- The iOS bundle ID and Android application ID are both `com.manicpixeldream.gavel`.
- Firebase project access; FlutterFire CLI available.
- iOS deployment target remains 15.0+ (meets Firebase minimum).

## Bootstrap progress

- [x] Installed and verified Firebase CLI 15.36.0 and FlutterFire CLI 1.5.0.
- [x] Added and locked the Core, Auth, Cloud Firestore, and Storage Flutter plugins.
- [x] Set the iOS and Android app display name to Gavel.
- [x] Sign in with `firebase login` and select `gavel-21e6a`.
- [x] Apply `com.manicpixeldream.gavel` to the iOS Runner and Android app.
- [x] Register iOS, Android, and web with FlutterFire and initialize Firebase from the generated options at startup.

FlutterFire is installed in the Dart pub cache. To refresh generated settings
with Flutter 3.50.0 on PATH, run this command from the app repository.

```sh
dart pub global run flutterfire_cli:flutterfire configure \
  --project=gavel-21e6a --platforms=ios,android,web \
  --ios-bundle-id=com.manicpixeldream.gavel \
  --android-package-name=com.manicpixeldream.gavel
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

- This iteration uses verified email/password accounts. Google and Apple sign-in can be added together if social sign-in is needed.
- `memberships/{uid}` stores one team ID and the invite code used to join. Only the account owner can read it. Clients can create it with a valid invite but cannot modify or delete it.
- Firebase Auth and a server-confirmed membership gate the normal web, iOS, and Android entry points. Demo builds use the original Welcome flow. The prep screens still use demo repositories, with browser storage scoped to the account and team.

## Ordered iterations

Suggested tags: `v2.1`, `v2.2`, … (or keep working on a `v2` branch until a release tag).

1. **Bundle ID and FlutterFire bootstrap** — complete. The app initializes Firebase on web, iOS, and Android. Existing prep screens continue to use the demo repositories until the later repository slices.

2. **Auth + team invite** — implemented.
   Account creation, sign-in, email verification, password reset, invite redemption, membership restoration, and sign-out. Cloud setup and browser smoke remain on the checklist.

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

## Auth + team invite checklist

- [x] Add Firebase Auth and membership gates on web, iOS, and Android.
- [x] Enforce verified email, valid invites, and one membership per account in Firestore rules.
- [x] Keep the guest demo and isolate account workspace storage.
- [x] Add account widget coverage and Firestore emulator rules tests.
- [x] `flutter analyze` passes.
- [x] `flutter test` passes (267 tests).
- [x] Production web build passes.
- [x] Firestore emulator rules tests pass.
- [ ] Enable Email/Password auth, provision Firestore and test invites, and deploy the reviewed rules to the target project.
- [ ] Complete manual Auth smoke in Edge or Chrome.
- [x] Commit the implementation.
- [ ] Tag after manual verification.

### Firebase setup and manual smoke

Enable Email/Password in Firebase Authentication. Set up Firestore and review
`firestore.rules` against the project's existing rules before deploying it. Using
the Firebase console or Admin SDK, create a document at `teams/{teamId}` and
another at `teamInvites/{code}` with `teamId` (string), `active` (boolean), and
`expiresAt` (Firestore timestamp). Use a random URL-safe code of 24–64 characters
(for example, `openssl rand -hex 16`). The code is reusable until it expires or
an administrator disables it. For access removal, disable the invite used and
delete the membership. The client has no invite administration UI.

1. In an incognito window, open a workspace URL. Create an account, send and
   open the verification email, then select **I verified my email**.
2. Try an invalid invite, then a valid one. Check that only the valid invite
   opens the workspace and that the account's membership exists in Firestore.
3. Reload to confirm membership persists. Sign out from Profile and sign in
   again. Check that a different account cannot see the first account's
   browser drafts.
4. Request a password reset, follow the email link, and sign in with the new
   password.

Run the rules tests in an isolated project with Node.js, Java 21, and Firebase CLI:

```sh
npm ci --prefix firestore_test
firebase emulators:exec --project demo-gavel --only firestore "npm --prefix firestore_test test"
```

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
