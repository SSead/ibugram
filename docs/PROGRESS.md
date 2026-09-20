# IBUgram — Build Progress

This is the live status page. Newest update at the top.

---

## 2026-09-20 · 09:50 — Claude budget exhausted; remaining work on Grok only

Opus is at 100% for this session. The two foundation architects already finished and
are committed. Remaining agents use **Cursor Grok 4.6** (and Composer if needed).
The Opus messaging agent was interrupted; a Grok agent is completing that layer from
the files already on disk rather than rewriting it.

**Also landed (not yet committed as a dedicated backend-features commit):**
Spaces, Events, and `POST /reports` — faculty-only official Spaces (403), capacity-1
RSVP overflow (409) proven with curl on :8092. Capacity uses `SELECT … FOR UPDATE`.

Still in flight: posts/social-graph backend, iOS DTO integration, messaging finish.

---

## 2026-09-20 · 09:25 — Phase 2 in flight, one integration debt identified

**Shipped and committed** (3 signed commits, 310 files tracked):

| Component | State |
| --- | --- |
| Database schema | 28 tables, 34 reversible migrations, trigger-maintained counters |
| Auth | Full OTP lifecycle verified by curl: domain rejection, throttling, refresh rotation, reuse detection kills the token family |
| Media | Upload with EXIF stripping, re-encode, thumbnails |
| `IBUgramKit` | Shared DTO package, 42 tests |
| Server | 52 tests, zero warnings |
| iOS foundation | Firebase removed, synchronized file groups, design system, 19 unit + 4 UI tests, 6 screenshots |
| iOS feed / posts / composer | Feed, post card, comment threads, likes, multi-image composer. 39 tests |

**Running now:** three backend teams (posts and social graph, Spaces and Events,
messaging and realtime) and one iOS team (profile, search, activity).

### Integration debt — DTO fragmentation

Four iOS teams each needed the same model types before the real `IBUgramKit` existed,
so they independently defined them in their own feature folders: `Post` landed in
`Features/Profile/ProfileDTOs.swift`, `Comment`, `Event` and `Place` in
`Features/Activity/ActivityDTOs.swift`, `SpaceSummary` in
`Features/Search/SearchDTOs.swift`, and the platform architect's `IBUgramKitStubs.swift`
holds a further fifteen.

This was a predictable cost of starting the client before the contract package compiled,
and it is already causing a visible defect: the post card cannot render its Space, Event
or location chips because the `Post` type it sees — the one Profile defined — lacks those
fields.

`IBUgramKit` now exists with the complete, contract-accurate DTOs. A single integration
task will delete every local duplicate and switch the app to the package, which is why
no agent was allowed to edit the package or the stubs file: the duplicates are
concentrated in known places rather than scattered.

**Next:** integration pass on the client, then the standout features (on-device
intelligence, offline outbox, map, widget), then QA, seeded demo data and the report.
