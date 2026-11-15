# v4 — ChatGPT LLM (researcher and case brief)

**Status:** Planned  
**Purpose:** Real AI researcher and case-brief parsing via ChatGPT, grounded in the team’s case packet.

Root roadmap: [`plan.md`](../../plan.md).  
This is the former **v3: ChatGPT** section, renumbered to v4 so it follows Firebase (v2) and device validation (v3).

## Goal

Back `ResearchService`, `CaseBriefService`, and exam “Suggest with AI” with ChatGPT through Firebase Cloud Functions, with citations grounded in uploaded case materials (RAG), without shipping the OpenAI API key in the app.

## Non-goals

- No new Firestore schema redesign beyond what v2 already provides for briefs/sources (extend carefully).
- No replacing the citation chip / “Cited in” UX from v0.6 — reuse it.
- No coach/judge/scrimmage features (v5).

## Prerequisites

- v2 Auth + team membership working (Cloud Functions must verify the Firebase Auth user and team).
- Case packet upload path (Firebase Storage from v2) available for text extraction.
- OpenAI API key stored in Secret Manager (never in the Flutter client or git).
- Prefer v3 device smoke already green so LLM UX can be checked on phone keyboards/layouts, but web can start earlier if needed.

## Architecture / swap-in strategy

- App calls Cloud Functions: `researchAsk`, `parseCaseBrief`, `suggestQuestions`.
- Each function checks Auth + team membership, then calls OpenAI with the server-side key.
- Add `OpenAIResearchService` and `OpenAICaseBriefService` implementing the **existing v1 interfaces** so Research, Case brief, and Examination pages do not change.
- Wire production providers to OpenAI impls; keep mocks for tests and offline demos.

### Grounding (RAG)

- On packet upload: extract text, chunk, store embeddings.
- Questions retrieve the most relevant chunks; the model must cite them.
- Keeps answers tied to the case record instead of invented facts.

### Structured output

- Request JSON matching a schema (answer points + citations with source ID and page).
- App renders the same citation chips and “Cited in” tracking from v0.6.

### Case brief parsing

- One call per packet → key facts, evidence linkages, likely opposing-counsel arguments.
- Persist under `cases/{caseId}/brief`.

### Product guardrails

- Stream responses for a fast-feeling chat.
- Rate-limit and cap usage per team.
- System prompt aimed at students (explains reasoning; does not write full scripts unless asked).
- Moderation checks.

## Ordered iterations

1. **Cloud Functions skeleton + secrets**  
   Deploy callable functions; Auth/team checks; Secret Manager for OpenAI key; no key in app.

2. **OpenAI service adapters**  
   `OpenAIResearchService` / `OpenAICaseBriefService` behind existing interfaces; feature-flag or environment switch from mocks.

3. **Research Ask with structured citations**  
   Streamed answers; JSON schema; map to existing chat bubbles and citation chips.

4. **Packet ingest + RAG**  
   Extract/chunk/embed on upload; retrieve chunks per question; require citations to retrieved sources.

5. **Case brief parse pipeline**  
   `parseCaseBrief` → store brief; Case tab reads live brief instead of mock.

6. **Exam suggestions**  
   `suggestQuestions` grounded in witness/affidavit context; user still explicitly adds suggestions for review (same product rule as v0.9).

7. **Guardrails + eval**  
   Rate limits, moderation, student-oriented system prompt; small eval set of case questions with expected citations.

## Done checklist (per slice)

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (fake HTTP / recorded JSON for client services)
- [ ] Cloud Function tests in the emulator when functions change
- [ ] Manual smoke: Research Ask and/or Case brief path touched by the slice (web; phone if available)
- [ ] Confirm no OpenAI key in client binaries or repo
- [ ] Commit; tag when the slice is reviewable

## Testing notes

- Client services: fake HTTP client + recorded JSON responses.
- Cloud Functions: emulator tests.
- Quality: small evaluation set of case questions with expected citations.
- Keep mock services working for CI without network/OpenAI credentials.

## Risks / ordering notes

- Depends on v2 Auth, Storage, and team rules — do not call OpenAI from the client as a shortcut.
- Cost and abuse: rate limits before wide team use.
- Hallucinations: require RAG citations; UI should degrade honestly when sources are missing.
- Bundle ID / mobile signing are v2↔v3 concerns; this version should not reopen ID changes.
