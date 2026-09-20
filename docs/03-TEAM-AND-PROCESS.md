# Team and Process

## Roles

| Role | Model | Responsibility |
| --- | --- | --- |
| Project Owner | Opus 5 | Product decisions, scope, sequencing, dispatch, integration, all git commits |
| Backend Architect | Opus 5 | Shared contract package, Vapor foundation, database schema |
| iOS Platform Architect | Opus 5 | Xcode project, app architecture, design system, app shell |
| Backend feature engineers | Grok / Composer | Endpoint groups against the frozen contract |
| iOS feature engineers | Opus for stateful/concurrent work, Grok for screen work | Feature modules |
| Code reviewers | Opus for architecture and security, Grok for style and correctness | Gate before commit |
| QA engineer | Opus | Test suites, seeded demo data, screenshot capture |
| Technical writer | Opus | The SDP report |

**Model selection rationale.** Opus is reserved for work where a wrong decision is
expensive to unwind: the API contract, the database schema, concurrency-sensitive
infrastructure (the API client's token refresh coalescing, the WebSocket actor, the
offline outbox), security code, and the report. Screen-level SwiftUI work, CRUD
endpoints against a frozen contract, test authoring and routine review go to cheaper
models, because the contract and the design system already constrain the answer and a
review gate catches the rest.

## Working rules

1. **The contract is frozen.** `01-API-CONTRACT.md` is the single source of truth.
   Server and client teams never negotiate directly; they both implement the document.
   A change requires the Owner to amend the document and the decision log.
2. **Strict file ownership.** Every agent is given an exclusive set of paths. Agents run
   concurrently in one working tree, so overlapping writes are the main failure mode and
   are prevented by assignment, not by merge.
3. **No agent runs git.** The Owner commits at phase boundaries. This keeps history
   readable and avoids index contention between concurrent agents.
4. **Nothing is committed unreviewed.** Every batch of feature work passes a review
   agent, and the security-sensitive surfaces additionally pass a dedicated review.
5. **Verification is part of the task, not a follow-up.** A task is not done until the
   agent has compiled it, run its tests, and pasted real output into its report.
   Claims without output are treated as unverified.
6. **Comments are a code smell here.** `02-ENGINEERING-STANDARDS.md` §1 is enforced in
   review. Readable names and small functions instead.

## Phases

| Phase | Content | Parallelism |
| --- | --- | --- |
| 0 | Repository, product spec, API contract, standards | Owner |
| 1 | Shared contract package, Vapor foundation and schema; Xcode modernization, architecture, design system | 2 agents |
| 2 | Backend feature groups; iOS feature modules | 6–8 agents |
| 3 | Standout features: Spaces, Events and map, on-device intelligence, offline outbox, widget and App Intents | 5 agents |
| 4 | Integration, seeded demo data, QA, accessibility pass, screenshots | 3 agents |
| 5 | Report authoring | 2 agents |

Phase 1 is the critical path: nothing downstream can start until the contract compiles
and the app builds, which is why both foundation tasks were given the strongest model.
