# Detailed version plans

Root [`plan.md`](../../plan.md) is the only top-level roadmap. This folder holds the agent-ready detail for each version.

## How to use with an agent

1. Open `@plan.md` and find the version in the **Agent routing** table.
2. Open the matching file here (for example `@docs/plans/v2-firebase-firestore.md`).
3. Ask for one slice at a time. Example:

```text
Build the next slice of @docs/plans/v2-firebase-firestore.md
Follow guiding rules in @plan.md.
Verify with flutter analyze and flutter test only. Give 3–5 manual smoke steps when done.
```

## Files

| File | Version |
|---|---|
| [v1-alpha.md](v1-alpha.md) | v0.1–v1.0 alpha completion record |
| [v2-firebase-firestore.md](v2-firebase-firestore.md) | Firebase Auth, Firestore, Storage, FCM |
| [v3-mobile-device-testing.md](v3-mobile-device-testing.md) | iPhone + Android device validation |
| [v4-chatgpt-llm.md](v4-chatgpt-llm.md) | ChatGPT researcher / case brief via Cloud Functions |
| [v5-prelaunch-and-future.md](v5-prelaunch-and-future.md) | Pre-launch extras and later product ideas |

Milestone review notes stay in `docs/v0.*-review.md` (do not delete).
