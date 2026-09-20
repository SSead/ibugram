# Decision Log

Architectural and product decisions, newest last. Each entry records what was decided,
why, and what was given up.

---

### D-001 — Replace Firebase with a self-owned Vapor + PostgreSQL backend
**Date:** 2026-09-20 · **Decided by:** Project Owner

The 2023 prototype used Firebase Auth, Firestore and Google Sign-In.

**Decision:** remove Firebase entirely. The backend is a Vapor 4 service backed by
PostgreSQL 14, with a shared `IBUgramKit` Swift package defining the DTOs compiled
into both the server and the iOS client.

**Why:**
1. The SDP requires an entity-relationship model of the database (Chapter 3) and
   unit/integration/system test results (Chapter 5). A relational schema and an owned
   test harness satisfy both directly; Firestore's schemaless collections do not.
2. Firebase ties the project to a console account that cannot be provisioned or
   verified reproducibly, making the build non-self-contained for a defense.
3. Domain-restricted passwordless auth is a first-class requirement. Implementing it
   ourselves is straightforward and demonstrably correct; bending Firebase's Google
   Sign-In to enforce it is neither.
4. Owning the full stack in one language is the strongest engineering narrative for
   this project.

**Given up:** managed hosting, free push infrastructure, and Google SSO convenience.
Push notification transport is architected behind a protocol but delivered in-app over
WebSocket for v1.0, since APNs requires a paid developer account.

---

### D-002 — Passwordless email OTP instead of Google Sign-In
**Date:** 2026-09-20 · **Decided by:** Project Owner

**Decision:** authentication is a 6-digit one-time code sent to a university address,
exchanged for a short-lived JWT access token and a rotating refresh token.

**Why:** the membership rule is "you hold an `@ibu.edu.ba` or `@stu.ibu.edu.ba`
mailbox". Proving control of that mailbox *is* the membership test, so OTP enforces the
requirement directly rather than as a post-hoc check on an OAuth identity. It also
removes password storage from the system entirely, which simplifies the security
analysis in Chapter 6.

**Given up:** one-tap sign-in. Mitigated by a 60-day rotating refresh token, so users
authenticate roughly twice a year.

---

### D-003 — iOS 18 minimum, Swift 6 strict concurrency
**Date:** 2026-09-20 · **Decided by:** Project Owner

**Decision:** raise the deployment target from iOS 17 to iOS 18 and enable Swift 6
language mode across all targets.

**Why:** the project's stated purpose is to demonstrate current native iOS competence.
Swift 6 data-race safety, mature `@Observable`, and SwiftData are the modern baseline,
and iOS 18 is two major versions behind the current release, so the compatibility cost
is negligible for a university-internal app.

---

### D-004 — Xcode project uses synchronized file groups
**Date:** 2026-09-20 · **Decided by:** Project Owner

**Decision:** upgrade `project.pbxproj` to `objectVersion` 77 and use
`PBXFileSystemSynchronizedRootGroup` so source files on disk are compiled without
per-file project edits.

**Why:** the project grows from 12 to well over a hundred Swift files. Hand-editing
`project.pbxproj` for each is the single most likely source of merge corruption and
build breakage across parallel contributors. Synchronized groups eliminate the class of
problem.

---

### D-005 — Discover ranking formula
**Date:** 2026-09-20 · **Decided by:** Project Owner (ratifying the posts team)

`GET /feed/discover` ranks posts from the last 21 days (blocked authors excluded):

**score = exp(−age_hours / 36) × (1 + ln(1 + likes) + 1.6 ln(1 + comments)) × department_boost**

Department boost is 1.3 when author and viewer share a department, else 1.0. Tie-break
is `created_at DESC`, then `id DESC`. Cursors are keyset against the ranked row, not
offsets.

**Why:** a 36-hour half-life matches campus checking cadence (today plus yesterday).
Comments outrank likes because they take more effort. Same-department affinity is the
one university-specific signal a generic Instagram clone would not have.

**Given up:** collaborative filtering and a learned ranker. Those need production
traffic this project does not have.
