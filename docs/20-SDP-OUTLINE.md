# Senior Design Project — Report Outline and Evidence Plan

The report is `Senior Design Project.md` at the repository root. The department's
template fixes the chapter structure; the notes below fix *what goes in each chapter*
and, critically, **what artefact each engineering team must produce as evidence**.

The existing document is a template with placeholder text ("This section should give a
brief system overview…"). Every one of those paragraphs gets replaced.

## Target length

Roughly 60–80 pages of substance. The chapters carrying real weight are 2 (System
Analysis), 3 (Application Design), 4 (Implementation) and 5 (System Testing).

## Front matter

| Item | Action |
| --- | --- |
| Title page | Keep, correct the year to 2026 |
| Approval page | Keep as-is; mentor and committee names are the student's to fill |
| Declaration | Keep, correct the date |
| Abstract | Rewrite — the current one predates the actual feature set and says nothing about the architecture |
| Acknowledgments | Replace the template's boilerplate (it still reads "I thank my husband") with a short, honest paragraph |
| Table of contents, tables, figures | Regenerate to match the final document |
| Abbreviations | Expand: API, APNs, CRUD, DTO, ER, JWT, ORM, OTP, REST, SDK, SPM, SQL, TLS, UI/UX, URL, UUID, WS |

## Chapter 1 — Introduction

1.1 **Background** — the university context and why a general-purpose network does not
serve it: no verified membership boundary, no notion of a department or a course, campus
events buried in noise.

1.2 **Objective** — two objectives, stated plainly. The product objective (a closed,
verified campus network). The personal engineering objective: the author is an
experienced Android and React Native developer who had never shipped native iOS; this
project exists to close that gap. Say this outright — it is the honest framing and it
justifies the technology choices.

1.3 **Significance** — consolidation of campus content, verified identity, and the
privacy posture that follows from on-device analysis.

1.4 **Structure of the paper** — a real roadmap, replacing the template's sample table
and sample figure.

## Chapter 2 — System Analysis

- Product perspective and scope; explicit out-of-scope list (Stories, Reels, video, ads).
- Actors and their capabilities → **Evidence: use-case actor table.**
- Functional requirements, numbered `FR-n`, traceable to features.
- Non-functional requirements, numbered `NFR-n` → source: `00-PRODUCT-SPEC.md` §5.
- Feasibility: technical, schedule, and economic (self-hosted vs managed backend cost).
- Constraints and risks with mitigations, including the honest ones: no paid Apple
  developer account, so APNs is architected but not delivered; single developer.
- Success criteria → source: `00-PRODUCT-SPEC.md` §6.
- **Comparison against Firebase**, presented as an engineering trade-off study. This is
  where decision D-001 is defended. → source: `90-DECISION-LOG.md`.

## Chapter 3 — Application Design

The template explicitly asks for use case, activity, class, sequence, communication and
ER diagrams. All diagrams authored as Mermaid so they are version-controlled and
regenerable.

| Diagram | Owner | Status |
| --- | --- | --- |
| System context | Architecture | — |
| Use case (per actor) | Owner | — |
| Class diagram — client | iOS Architect | from `11-IOS-ARCHITECTURE.md` |
| Class diagram — server | Backend Architect | from `10-DATA-MODEL.md` |
| **ER diagram** | Backend Architect | from `10-DATA-MODEL.md` |
| Sequence — OTP sign-in | Backend Architect | — |
| Sequence — post creation with on-device alt text | iOS + Backend | — |
| Sequence — realtime message delivery over WebSocket | Messaging team | — |
| Activity — feed load with offline fallback | Offline team | — |
| Component / package diagram | Architecture | — |
| Navigation map | iOS Architect | — |

Also: API design rationale (why cursor pagination, why a shared DTO package, why the
error envelope), and the security design (OTP hashing, token rotation, domain
enforcement).

## Chapter 4 — Implementation

- Languages and frameworks with justification: Swift 6, SwiftUI, Vapor, Fluent,
  PostgreSQL, SwiftData, Vision, Natural Language, MapKit, EventKit, WidgetKit,
  App Intents.
- Hardware/software environment and how to run the system.
- The shared-`IBUgramKit` technique and what it buys — this is a genuinely interesting
  implementation detail worth a section of its own.
- Feature walkthrough with **screenshots**, one subsection per feature area.
- Selected code listings: the `APIClient` refresh-coalescing actor, the OTP verification
  service, the offline outbox replay, the Vision alt-text pipeline. Short excerpts only.
- **Evidence required: `docs/screenshots/` populated for every P0 and P1 feature, light
  and dark mode, captured on iPhone 17 Pro.**

## Chapter 5 — System Testing

- Strategy: the test pyramid as actually applied here.
- **Unit tests** — `IBUgramKit` coding, server services, client view models.
- **Integration tests** — server endpoints against a real PostgreSQL database.
- **System / UI tests** — XCUITest journeys: sign in, post, like, comment, follow, send
  a message.
- Manual test matrix for things not automated: accessibility with VoiceOver, offline
  behaviour, Dynamic Type at XXL.
- Performance measurements against NFR-1 and NFR-2 with the method stated.
- **Evidence required: real test counts, real pass/fail output, real timings. No
  invented numbers — every figure in this chapter must be reproducible by running a
  command that appears in the text.**

## Chapter 6 — Maintenance Analysis

- Maintainability: layering, the shared contract as a single source of truth, what a new
  contributor must read.
- Data integrity: constraints, cascade rules, counter correctness, migration discipline.
- Security: threat model, OTP and token handling, authorization checks, input validation,
  EXIF stripping, rate limiting, and the known gaps.
- Backup, restore and crash recovery; the offline cache as incidental resilience.
- Administration and moderation.
- Future work: APNs, video, web client, SSO against university identity, analytics.

## Chapter 7 — Conclusion

Benefits delivered, what the author learned moving from Android/React Native to native
iOS and to server-side Swift, limitations faced honestly, and recommendations.

## References

Replace the template's `Surname, N.` placeholders with real, correctly formatted
citations: Apple's Swift, SwiftUI, Vision, Natural Language, SwiftData and Human
Interface Guidelines documentation; the Vapor documentation; the PostgreSQL manual;
RFC 6749 and RFC 7519; and literature on university social platforms and student
engagement.

## Appendices

A — Full API reference (from `01-API-CONTRACT.md`)
B — Database schema DDL
C — Test output transcripts
D — How to build and run the system
