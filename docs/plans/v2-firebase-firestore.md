# v2 — Firebase and Firestore

**Status:** FlutterFire bootstrap, email Auth + team invites, and the Firestore read path are implemented. Firebase setup and browser smoke are pending. Shared writes are implemented in code and await rollout. Offline persistence remains open.

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

- `teams/{teamId}` stores `activeCaseId` and has `members`, `cases`, `tasks`, `sessions`, and `chat` subcollections.
- The active case document has `exhibits`, `witnesses`, `affidavits`, `stipulations`, `timingRules`, and `brief/current`. Research builds its sample source catalogue from the case materials.
- Record document IDs match model IDs. Chat records carry `caseId`. Roster IDs and the IDs referenced by task assignees and practice participants match Firebase Auth UIDs for real members.
- Administrators configure trial roles under `teams/{teamId}/cases/{caseId}/roles`, with one to three responsibilities per role. They set the optional `teamRole` field on roster entries to `captain` or `coach` to grant assignment authority. Members cannot edit roster permissions.
- A role assignment fills the role's `assigneeId` and creates the exact responsibility tasks in one transaction. A practice follow-up stores its `sessionId` and links to that session's agenda.

### Auth model

- Accounts can use verified email/password or Google sign-in on the web. Google uses the same team invite and membership checks. Native apps use email/password.
- `memberships/{uid}` stores one team ID and the invite code used to join. Only the account owner can read it. Clients can create it with a valid invite but cannot modify or delete it.
- Firebase Auth and a server-confirmed membership gate the normal web, iOS, and Android entry points. Demo builds use the original Welcome flow. The shared workspace reads Firestore data. Private draft storage remains scoped to account and team in the browser.

## Ordered iterations

Suggested tags: `v2.1`, `v2.2`, … (or keep working on a `v2` branch until a release tag).

1. **Bundle ID and FlutterFire bootstrap** — complete. The app initializes Firebase on web, iOS, and Android. The guest demo continues to use demo repositories.

2. **Auth + team invite** — implemented.
   Account creation, sign-in, email verification, password reset, invite redemption, membership restoration, and sign-out. Cloud setup and browser smoke remain on the checklist.

3. **Firestore repositories (read path)** — implemented.
   Signed-in members read their team's case, roster, task status, practice schedule, and active-case chat history via Firestore subscriptions. The case brief and packet materials update from Firestore. Private drafts stay local. An administrator can seed State v. Harmon for one team using the commands below.

4. **Write path + real-time UX** — in progress.
   Task completion, shared chat, captain/coach role assignments, and participant
   follow-ups are implemented. Task snapshots update shared readiness.
   Transactions require a connection. Offline behavior and persistence remain open.

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
- [x] Enable Email/Password and Google Auth in the Firebase project and authorize localhost.
- [ ] Provision Firestore and test invites, and deploy the reviewed rules to the target project.
- [ ] Complete manual Auth smoke in Edge or Chrome.
- [x] Commit the implementation.
- [ ] Tag after manual verification.

### Firebase setup and manual smoke

Enable Email/Password in Firebase Authentication. For web Google sign-in, enable
Google under **Authentication → Sign-in method**, set Gavel's public display
name and support email, and add the web app's domain under **Authorized
domains**. Add `localhost` if you need to test with Flutter locally.

As of November 21, 2026, the project has Auth enabled and no default Firestore
database or Firestore rules release. Before testing an invite on the live app,
create the default database in the chosen region, seed a team, and deploy the
reviewed Firestore rules. A successful Google sign-in only verifies the Auth step.

Set up Firestore and review
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

## Firestore read checklist

- [x] Connect case, roster, tasks, practice schedule, and chat to Firestore reads.
- [x] Limit reads to the signed-in member's own team.
- [x] Keep the guest demo and browser-local drafts.
- [x] Verify the Harmon seed import and team access rules in the emulator (62 seed records, two rules tests).
- [x] Run Flutter analysis, tests (268 passed), and a production web build.
- [ ] Deploy the reviewed rules and seed the target team.
- [ ] Complete manual browser smoke with a seeded team.

### Seed and verify a team

Create the test account in Firebase Auth and note its UID. Export the fictional
case and map the demo user's assignments to that UID. Then run the import with
Firestore administrator Application Default Credentials. Use a fresh test team
or a team that has no Harmon records. The import sets its active case and creates
the seed records in one commit. It aborts if any seed record already exists. The export
includes trial roles and gives the supplied test account captain authority in
the sample roster.

```sh
flutter test tool/export_harmon.dart \
  --dart-define=HARMON_OUTPUT=/tmp/gavel-harmon.json \
  --dart-define=HARMON_MEMBER_UID=YOUR_TEST_USER_UID
node tool/import_harmon.mjs YOUR_FIREBASE_PROJECT YOUR_TEAM_ID /tmp/gavel-harmon.json
```

1. Sign in with a verified account and redeem an invite for the seeded team.
2. Check that Case shows Harmon, Team shows the roster, Profile shows the mapped
   tasks, and Practice Schedule and Team Chat show imported records.
3. Change a task title or status in the Firebase console. Confirm it updates in
   Gavel without a reload. Use Profile to complete or reopen a task assigned to your account.
4. Sign in as a member of a different team and confirm the Harmon data is unavailable.

## Shared write checklist

- [x] Let verified team members complete or reopen their own tasks. Rules allow only the completion field to change.
- [x] Keep task status and readiness in sync through Firestore snapshots.
- [x] Preserve the previous task state on a failed write and offer retry.
- [x] Verify task writes with Flutter analysis, 270 Flutter tests, and three Firestore rules tests.
- [ ] Deploy the reviewed rules and check task completion across two signed-in team accounts.
- [x] Let rostered members send messages with task and exhibit links in their team's active case.
- [x] Preserve failed drafts and retry the same message ID. Confirmed chat messages use the server timestamp.
- [x] Verify shared sends with Flutter analysis, 271 Flutter tests, the production web build, and four Firestore rules tests.
- [ ] Deploy the reviewed rules and check sending and receiving across two team accounts.
- [x] Let captains and coaches assign a role and create all responsibility tasks atomically.
- [x] Let rostered participants assign practice follow-ups to fellow participants and keep the draft on failure.
- [x] Verify role assignments and follow-ups with Flutter analysis, 276 Flutter tests, the web build, and seven emulator rules tests. The Harmon seed imported 76 records.
- [ ] Deploy the reviewed rules and verify assignments and follow-ups across two signed-in team accounts.
- [ ] Verify offline behavior and enable persistence as appropriate.

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
