# IBUgram — Build Progress

This is the live status page. Newest update at the top.

---

## 2026-09-20 · 08:10 — Phase 0 complete, Phase 1 dispatched

**Where things stand.** The repository is under git for the first time. The 2023
prototype (12 Swift files, four placeholder screens, a Firebase login) is committed as
the baseline so the delta is visible.

**Decisions made this phase** — full reasoning in `90-DECISION-LOG.md`:
- Firebase is out. The backend is now a Vapor 4 service on PostgreSQL, with a shared
  `IBUgramKit` Swift package used by both the server and the app.
- Authentication is passwordless email OTP restricted to the two university domains.
- iOS 18 minimum, Swift 6 strict concurrency.

**Scope locked** in `00-PRODUCT-SPEC.md`. The Instagram-equivalent core (feed, posts,
profiles, follow graph, search, direct messaging, notifications) plus five standout
capabilities chosen to be defensible in front of a committee:

1. **Spaces** — clubs, departments and courses as real communities
2. **Campus Events** — RSVP, MapKit campus map, EventKit calendar integration
3. **On-device intelligence** — Vision alt-text and Natural Language topic extraction,
   no image ever leaves the phone
4. **Offline-first** — SwiftData cache with a replayable outbox
5. **System integration** — WidgetKit widget and App Intents for Siri

**Team dispatched this phase**
| Agent | Model | Assignment |
| --- | --- | --- |
| Backend Architect | Opus | `IBUgramKit` DTOs, Vapor skeleton, full database schema and migrations |
| iOS Platform Architect | Opus | Xcode project modernization, Firebase removal, design system |

**Next.** Once the foundation compiles on both sides, feature teams fan out in
parallel against the frozen API contract in `01-API-CONTRACT.md`.
