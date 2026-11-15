# v3 — iPhone and Android device testing

**Status:** Planned  
**Purpose:** Validate the app on real phones (safe areas, gestures, keyboards, Dynamic Type) after Firebase IDs are stable.

Root roadmap: [`plan.md`](../../plan.md).  
This is the former **Beta: iPhone device testing (and Android)** section, renumbered to v3 so Firebase (v2) can land first.

## Goal

Prove Gavel works on a connected iPhone (and Android emulator or device): layout, navigation gestures, keyboard avoidance, and larger text — with the same feature set already built for web/alpha.

## Non-goals

- Not a place to redesign product features or add Firebase schema (do that in v2).
- Not live ChatGPT integration (v4).
- Not coach/judge/scrimmage expansions (v5).

## Prerequisites

- v2 FlutterFire config complete with the **final** bundle ID / `applicationId` (see [v2-firebase-firestore.md](v2-firebase-firestore.md) risks).
- Student Mac with Xcode and CocoaPods; physical iPhone for the primary path.
- Apple ID team for Signing & Capabilities; Developer Mode on the phone; trust the developer certificate.
- Android: emulator or device with matching `applicationId`.

## Architecture / swap-in strategy

No new repository interfaces required. This version hardens **platform shells** already prepared in v1:

- `GavelBottomNav` wrapped in `SafeArea`
- Cupertino-style slide-back via theme page transitions
- Research and team chat input bars must stay above the on-screen keyboard

Prefer fixing layout/platform bugs over inventing parallel mobile-only screens.

## Ordered iterations

1. **One-time Mac / Xcode setup**  
   Install Xcode and CocoaPods; open `ios/Runner.xcworkspace`; Signing & Capabilities → Team; confirm bundle ID matches v2; display name "Gavel".

2. **First device run**  
   `flutter devices`, then `flutter run -d <iphone-id>`. Smoke Home, Case, Research, Team, Me.

3. **iOS-specific page pass** (every page)  
   - Safe areas (notch and home indicator) around bottom nav  
   - Swipe-back on pushed pages  
   - Research and team chat input bars above keyboard  
   - Dynamic Type at larger text sizes  

4. **Integration tests on device**  
   `flutter test integration_test -d <iphone-id>` (extend alpha Chrome flow as needed).

5. **Android smoke**  
   Same critical paths on emulator or physical device.

6. **Done-checklist expansion**  
   Document that future slices include manual smoke on iPhone (Mac) as well as Edge (Windows).

## Done checklist (per slice)

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Manual smoke on **iPhone** for pages touched (Mac)
- [ ] Manual smoke on **Android** when the slice claims Android coverage
- [ ] Platform checks for that slice: safe area / swipe-back / keyboard / Dynamic Type as applicable
- [ ] Commit; tag when the device milestone is reviewable

## Testing notes

- Agents still do not drive browsers or devices; developers run device smoke.
- CI continues unsigned `flutter build ios --no-codesign` on macOS; device runs are local.
- Prefer reproducing layout bugs with widget tests at large text scale when feasible; confirm on hardware.

## Risks / ordering notes (v2 ↔ v3)

- **Do not change bundle ID here** unless v2 Firebase/Apple config is updated in lockstep. Mismatched IDs break GoogleService, push, and store builds.
- If v2 skipped finalizing the ID, stop and fix IDs in v2 before deep device work.
- APNs / push end-to-end belongs after FCM setup in v2 and a physical iPhone here.
- Keyboard and safe-area fixes should stay in shared widgets/theme so web and phone stay aligned.
