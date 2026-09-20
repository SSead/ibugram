# IBUgram — Product Specification v1.0

Owner: Project Owner Agent
Status: Approved, locked for v1.0
Last updated: 2026-09-20

## 1. Product statement

IBUgram is a closed social network for the International Burch University community.
Membership is restricted by email domain: only `@ibu.edu.ba` (faculty and staff) and
`@stu.ibu.edu.ba` (students) may hold an account. Inside that boundary the product
behaves like Instagram — a photo-centric feed, profiles, a social graph and direct
messaging — extended with three capabilities a general-purpose network cannot offer a
university: **Spaces**, **Campus Events**, and **on-device content intelligence**.

Explicitly out of scope for v1.0: Stories, Reels, video posts, advertising, public
(unauthenticated) access.

## 2. Platform decisions (locked)

| Concern | Decision |
| --- | --- |
| Client | Native iOS, SwiftUI, iOS 18.0 minimum, Swift 6 strict concurrency |
| Server | Vapor 4 (Swift), PostgreSQL 14, Fluent ORM |
| Shared code | `IBUgramKit` Swift package — DTOs and endpoint contract compiled into **both** client and server |
| Auth | Passwordless email OTP, domain-restricted, JWT access + refresh |
| Realtime | WebSocket (messaging, presence, typing, live notifications) |
| Media | Server-side storage with on-disk blob store behind a `MediaStore` protocol |
| Local persistence | SwiftData cache + offline outbox |

Firebase has been removed. Rationale: the SDP requires an entity-relationship model and
demonstrable unit/integration/system testing, both of which a relational, self-owned
backend supports directly; and owning the full stack in one language is the defensible
engineering story for this project.

## 3. Actors

| Actor | Source | Capabilities |
| --- | --- | --- |
| Student | `@stu.ibu.edu.ba` | Full social participation; join Spaces; RSVP to Events |
| Faculty / Staff | `@ibu.edu.ba` | Everything a Student can do, plus create **official** Spaces and publish Events to the whole campus. Carries a verified badge. |
| Moderator | Flag on account | Review reports, hide content, suspend accounts |
| System | — | OTP delivery, notification fan-out, feed ranking, event reminders |

## 4. Feature set

### 4.1 Identity and access (P0)
- Email entry → domain validation → 6-digit OTP → JWT session.
- Role derived from domain. Faculty accounts are badge-verified automatically.
- First-run profile setup: display name, username, avatar, department, year of study.
- Refresh-token rotation; sessions listed and revocable in Settings.
- Keychain-backed token storage; biometric app lock (optional).

### 4.2 Feed (P0)
- Two feeds: **Following** and **Discover** (campus-wide, ranked).
- Cursor-paginated, pull-to-refresh, infinite scroll, skeleton loading states.
- Post card: author, media carousel, caption with linkified hashtags/mentions, like,
  comment, save, share, location/Space/Event chips.
- Double-tap to like with animation; optimistic like state.

### 4.3 Posts (P0)
- Composer: pick up to 10 images, crop, caption, hashtags, mentions, optional Space,
  optional campus location, optional attached Event.
- Edit caption, delete post, disable comments, archive.
- Comments with one level of replies, comment likes.
- Saves/bookmarks with collections.

### 4.4 Profiles and social graph (P0)
- Avatar, display name, username, bio, department, role badge, counts.
- Post grid, saved tab (self only), tagged tab.
- Follow/unfollow, followers and following lists, follow-back indicator.
- Block and report.

### 4.5 Search and discovery (P0)
- Unified search across users, hashtags, Spaces and post captions (Postgres full-text).
- Recent searches, trending hashtags, suggested people from your department.

### 4.6 Direct messaging (P0)
- 1:1 and group conversations over WebSocket.
- Text and image messages, typing indicators, read receipts, presence, unread badges.
- Message requests from non-followed users.

### 4.7 Notifications (P0)
- Activity feed: likes, comments, replies, follows, mentions, Space invites, Event reminders.
- Delivered live over the WebSocket while connected; fetched on cold start.
- Grouped ("X and 4 others liked your post"), read/unread state.

### 4.8 Spaces — standout (P1)
Clubs, departments and courses as first-class communities.
- Space profile: banner, description, member list, moderators, official badge.
- Join/leave; public, request-to-join, and invite-only visibility.
- Space feed; posting to a Space cross-posts into member feeds.
- Only faculty/staff may create **official** Spaces; students create community Spaces.

### 4.9 Campus Events — standout (P1)
- An Event is an entity attachable to a post: title, start/end, location (campus place
  or coordinates), capacity, RSVP list.
- RSVP states: going / interested / not going, with capacity enforcement.
- **Campus map** (MapKit) showing upcoming events and geo-tagged posts pinned to campus.
- **Add to Calendar** via EventKit.
- "Happening now" rail at the top of the feed.

### 4.10 On-device intelligence — standout (P1)
All inference runs on the device. No image ever leaves the phone for analysis.
- **Vision**: automatic alt-text generation and scene classification at compose time,
  surfaced as an editable suggestion; powers accessibility labels on every image.
- **Natural Language**: hashtag and topic suggestion from the caption; language
  identification; sentiment used as a soft ranking signal.
- Rationale to defend: privacy-preserving, zero marginal server cost, works offline.

### 4.11 Offline-first — standout (P1)
- SwiftData mirrors feed, profiles, conversations and notifications.
- App is fully readable with no network.
- **Outbox**: posts, likes, comments and messages created offline are queued and
  replayed on reconnect with conflict resolution.
- Explicit network-state banner.

### 4.12 System extensions — standout (P1)
- **WidgetKit** home-screen widget: next campus event and unread activity count.
- **App Intents**: "Post to IBUgram", "What's happening at Burch?" exposed to Siri/Spotlight.

### 4.13 Accessibility and polish (P1)
- Full VoiceOver labelling, Dynamic Type through XXL, Reduce Motion respected,
  contrast-checked palette, complete dark mode, haptics.

### 4.14 Moderation and safety (P2)
- Report post/comment/user; moderator queue; hide and suspend actions; audit log.

## 5. Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Feed page (20 posts) returns in under 300 ms at p95 on the reference dataset |
| NFR-2 | Cold launch to rendered cached feed under 1.5 s |
| NFR-3 | All traffic over TLS in deployment; tokens only in Keychain |
| NFR-4 | Passwords never stored — OTP only; OTP expires in 10 minutes, 5 attempts max |
| NFR-5 | App remains usable read-only with zero connectivity |
| NFR-6 | Server test suite covers every endpoint; client covers view models and services |
| NFR-7 | Swift 6 strict concurrency enabled, zero warnings |
| NFR-8 | VoiceOver can complete every primary user journey |

## 6. Release definition of done

1. Server builds, migrates and passes its full test suite against PostgreSQL.
2. App builds for the iOS 26 simulator with zero warnings and passes unit + UI tests.
3. A seeded demo dataset produces a visually complete app for screenshots.
4. Every P0 and P1 feature is reachable from the UI.
5. `Senior Design Project.md` is complete with diagrams and screenshots.
