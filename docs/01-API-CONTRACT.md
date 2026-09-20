# IBUgram — API Contract v1.0

Status: **Authoritative.** Server and client both implement this document. Any change
requires a note in `docs/90-DECISION-LOG.md` and a matching update to `IBUgramKit`.

Base URL (development): `http://127.0.0.1:8080`
All paths are prefixed `/api/v1`.

## Conventions

- JSON, `snake_case` keys on the wire. `IBUgramKit` DTOs use `camelCase` Swift
  properties with a `.convertFromSnakeCase` / `.convertToSnakeCase` coding strategy.
- Timestamps: ISO-8601 with fractional seconds, UTC (`2026-09-20T07:31:12.482Z`).
- Identifiers: UUID v4 strings.
- Authentication: `Authorization: Bearer <access_token>`.
- Pagination: cursor based. Requests take `?limit=20&cursor=<opaque>`; list responses
  return `{ "items": [...], "next_cursor": "..."|null }`.

### Error envelope

Every non-2xx response is:

```json
{ "error": { "code": "otp_invalid", "message": "That code is not correct.", "details": {} } }
```

`code` is a stable machine-readable string; the client maps it to localized copy and
never displays `message` verbatim except as a fallback.

Canonical codes: `unauthorized`, `forbidden`, `not_found`, `validation_failed`,
`domain_not_allowed`, `otp_invalid`, `otp_expired`, `otp_throttled`, `rate_limited`,
`username_taken`, `conflict`, `payload_too_large`, `internal_error`.

## 1. Authentication

| Method | Path | Body | Response |
| --- | --- | --- | --- |
| POST | `/auth/request-code` | `{ email }` | `202 { "expires_at", "resend_after" }` |
| POST | `/auth/verify-code` | `{ email, code }` | `200 AuthSession` |
| POST | `/auth/refresh` | `{ refresh_token }` | `200 AuthSession` |
| POST | `/auth/logout` | `{ refresh_token }` | `204` |
| GET | `/auth/sessions` | — | `200 [Session]` |
| DELETE | `/auth/sessions/:id` | — | `204` |

`request-code` rejects any address whose domain is not `ibu.edu.ba` or
`stu.ibu.edu.ba` with `domain_not_allowed`. It is throttled to 1 request per 60s and
5 per hour per address. Responses are identical whether or not the account exists.

```
AuthSession {
  access_token: String        // JWT, 15 min
  refresh_token: String       // opaque, 60 days, rotated on every use
  expires_in: Int
  user: User
  needs_onboarding: Bool      // true until username + display_name are set
}
```

In `development` the OTP is additionally returned in the `request-code` response as
`debug_code` and printed to the server log. This field is absent in production.

## 2. Core resources

```
User {
  id, username, display_name, avatar_url?, bio?,
  role: "student" | "faculty",        // derived from email domain
  department?, year_of_study?,
  is_verified: Bool,
  counts: { posts, followers, following },
  viewer: { is_following, is_followed_by, is_blocked } | null,
  created_at
}

Media {
  id, url, thumbnail_url, width, height,
  alt_text?,                          // device-generated, user-editable
  blurhash?
}

Post {
  id, author: User, media: [Media], caption?,
  hashtags: [String], mentions: [User],
  space: SpaceSummary?, event: Event?, location: Place?,
  counts: { likes, comments },
  viewer: { has_liked, has_saved } | null,
  comments_enabled: Bool,
  created_at, edited_at?
}

Comment {
  id, post_id, author: User, body,
  parent_id?, reply_count, like_count,
  viewer: { has_liked } | null,
  created_at
}

SpaceSummary { id, slug, name, avatar_url?, is_official, member_count }

Space {
  ...SpaceSummary, banner_url?, description?, kind: "club"|"department"|"course"|"community",
  visibility: "public"|"request"|"invite",
  viewer: { membership: "none"|"pending"|"member"|"moderator"|"owner" } | null,
  created_by: User, created_at
}

Place { id?, name, latitude, longitude, is_campus_location: Bool }

Event {
  id, title, description?, starts_at, ends_at?,
  place: Place?, capacity?, host: User, space: SpaceSummary?,
  counts: { going, interested },
  viewer: { rsvp: "going"|"interested"|"none" } | null,
  post_id?
}

Conversation {
  id, kind: "direct"|"group", title?, avatar_url?,
  participants: [User], last_message: Message?,
  unread_count: Int, is_request: Bool, updated_at
}

Message {
  id, conversation_id, sender: User, body?, media: [Media],
  delivery: "sending"|"sent"|"read",        // client-side "sending" only
  read_by: [UUID], created_at
}

Notification {
  id, kind: "like"|"comment"|"reply"|"follow"|"mention"|"space_invite"|"event_reminder",
  actors: [User], group_count: Int,
  post: Post?, comment: Comment?, space: SpaceSummary?, event: Event?,
  is_read: Bool, created_at
}
```

## 3. Endpoints

### Users
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/users/me` | Current user |
| PATCH | `/users/me` | `display_name, bio, department, year_of_study, avatar_media_id` |
| POST | `/users/me/username` | `{ username }` → `username_taken` on conflict |
| GET | `/users/:username` | Public profile |
| GET | `/users/:username/posts` | Paginated |
| GET | `/users/:username/followers` \| `/following` | Paginated |
| POST \| DELETE | `/users/:id/follow` | Follow / unfollow |
| POST \| DELETE | `/users/:id/block` | Block / unblock |
| GET | `/users/suggested` | Same-department suggestions |

### Posts and feed
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/feed/following` | Reverse-chronological from followed users and Spaces |
| GET | `/feed/discover` | Ranked campus-wide |
| POST | `/posts` | `{ media_ids, caption, space_id?, event?, place?, comments_enabled }` |
| GET \| PATCH \| DELETE | `/posts/:id` | |
| POST \| DELETE | `/posts/:id/like` | |
| POST \| DELETE | `/posts/:id/save` | |
| GET | `/posts/:id/likes` | Paginated |
| GET | `/posts/:id/comments` | Paginated, threaded |
| POST | `/posts/:id/comments` | `{ body, parent_id? }` |
| DELETE | `/comments/:id` | |
| POST \| DELETE | `/comments/:id/like` | |
| GET | `/me/saved` | Saved posts |

### Spaces
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/spaces` | Browse and filter by `kind` |
| POST | `/spaces` | `is_official` only permitted for faculty |
| GET \| PATCH | `/spaces/:slug` | |
| GET | `/spaces/:slug/posts` \| `/members` | Paginated |
| POST \| DELETE | `/spaces/:slug/membership` | Join / leave, honours `visibility` |
| POST | `/spaces/:slug/members/:userID/role` | Moderator management |

### Events
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/events` | `?from=&to=&space_id=` upcoming |
| GET | `/events/happening-now` | Feed rail |
| GET | `/events/map` | `?bbox=` events and geo-tagged posts for MapKit |
| POST \| GET \| PATCH \| DELETE | `/events[/:id]` | |
| PUT | `/events/:id/rsvp` | `{ status }`, enforces `capacity` |
| GET | `/events/:id/attendees` | |

### Search
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/search` | `?q=&type=all\|users\|hashtags\|spaces\|posts` |
| GET | `/search/trending` | Trending hashtags |
| GET | `/hashtags/:tag/posts` | |

### Messaging
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/conversations` | `?filter=inbox\|requests` |
| POST | `/conversations` | `{ participant_ids, title? }`, idempotent for 1:1 |
| GET | `/conversations/:id/messages` | Paginated, newest first |
| POST | `/conversations/:id/messages` | `{ body?, media_ids?, client_id }` |
| POST | `/conversations/:id/read` | `{ up_to_message_id }` |
| POST | `/conversations/:id/accept` | Accept a message request |

`client_id` is a client-generated UUID enabling idempotent retry from the offline
outbox; the server returns the existing message if it has already seen that id.

### Notifications
| Method | Path |
| --- | --- |
| GET | `/notifications` |
| GET | `/notifications/unread-count` |
| POST | `/notifications/read` |

### Media
| Method | Path | Notes |
| --- | --- | --- |
| POST | `/media` | `multipart/form-data`, field `file`, optional `alt_text`. Max 10 MB, JPEG/PNG/HEIC. Returns `Media`. |

Uploaded media is stored, re-encoded to JPEG, stripped of EXIF, and a thumbnail is
generated. Files are served from `/media/:id`.

## 4. WebSocket

`GET /api/v1/ws?token=<access_token>` upgrades to a WebSocket.

Every frame is `{ "type": ..., "payload": ... }`.

Client → server: `ping`, `typing_start`, `typing_stop`, `subscribe_conversation`,
`unsubscribe_conversation`, `mark_read`.

Server → client: `pong`, `message_created`, `message_read`, `typing`,
`presence_changed`, `notification_created`, `unread_count_changed`.

The client reconnects with exponential backoff (1s → 30s cap) and re-subscribes on
open. Any gap is reconciled by refetching over REST.

## 5. Health

`GET /health` → `{ "status": "ok", "database": "ok", "version": "..." }` (unauthenticated).
Also served at `GET /api/v1/health` so a client that always prefixes needs no special case.

---

# Amendment 1 — 2026-09-20

Ratified by the Project Owner after the foundation implementation. Everything below is
part of the contract.

## A1.1 HTTP status codes

The original contract fixed error *codes* but not statuses. Clients must branch on
`error.code`, never on the status alone, but the mapping is now fixed:

| Code | Status |
| --- | --- |
| `validation_failed` | 422 |
| `otp_invalid`, `otp_expired` | 400 |
| `unauthorized` | 401 |
| `forbidden`, `domain_not_allowed` | 403 |
| `not_found` | 404 |
| `username_taken`, `conflict` | 409 |
| `payload_too_large` | 413 |
| `otp_throttled`, `rate_limited` | 429 |
| `not_implemented` | 501 |
| `internal_error` | 500 |

`not_implemented` is added to the canonical code list. It marks an endpoint that is
registered but not yet built; `details.endpoint` carries the route.

## A1.2 Access tokens may be revoked before they expire

A stateless JWT would stay valid until `exp` even after logout or detected refresh-token
theft, leaving a thief up to 15 minutes of access after revocation. The authenticator
therefore also requires the token's session *family* to still exist.

Revocation is per **family**, not per session, so an ordinary refresh does not invalidate
an access token the client still holds.

**Client requirement:** treat `401` as "attempt a refresh; if that fails, sign out",
regardless of whether `expires_in` has elapsed. Never trust the clock alone.

## A1.3 `needs_onboarding` is the only onboarding signal

`User.username` and `User.display_name` are non-optional, but an account exists between
verifying a code and completing onboarding. The server assigns a placeholder username
(`user_<prefix>`) and derives a display name from the email local part.

**Client requirement:** a populated `username` does **not** mean onboarding is complete.
Read `needs_onboarding`.

## A1.4 Added endpoints

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/media/:id/thumbnail` | Serves the `thumbnail_url` rendition |
| GET | `/users/:username/available` | Username availability, unauthenticated. Returns `{ "available": Bool }`. Added because onboarding was otherwise forced to probe `GET /users/:username` and read `not_found` as success. |
| POST | `/reports` | `{ post_id? , comment_id?, user_id?, reason }` — exactly one target. Moderation was in the product spec and data model but missing from the route table. |

## A1.5 Serialization notes

- UUIDs serialize **uppercase** (Foundation's `UUID` encoding). Parsing is
  case-insensitive; do not compare id strings against lower-cased literals.
- Full-text search uses PostgreSQL's `simple` configuration, not `english`. English
  stemming mangles Bosnian words and proper nouns, and Bosnian is not a built-in
  configuration.
- `GET /auth/sessions` returns a bare array, not a `Paginated` envelope. Session counts
  are inherently small.
- The WebSocket authenticates by `?token=` query parameter and therefore sits outside
  the bearer-token middleware.

## A1.6 Schema is frozen

The 28-table schema documented in `10-DATA-MODEL.md` covers the whole product. Feature
teams implement endpoints against it and do **not** add migrations. A genuine schema gap
is escalated to the Owner.

---

# Amendment 2 — 2026-09-20

Ratified after the client feature teams reported gaps. Unspecified request and response
shapes are pinned here to whatever the client already assumes, since those screens are
built and tested.

## A2.1 Pinned request and response bodies

| Endpoint | Shape |
| --- | --- |
| `POST /notifications/read` | Request `{ "ids": [UUID] }`. An empty array marks everything read. |
| `GET /notifications/unread-count` | Response `{ "count": Int }` |
| `GET /search` | Response `{ "users": [User], "hashtags": [Hashtag], "spaces": [SpaceSummary], "posts": [Post] }`. Each array is capped, and `type` narrows which are populated. |
| `POST /reports` | Request `{ "post_id"?, "comment_id"?, "user_id"?, "reason" }` — exactly one target. Added to §3 proper; it was only in Amendment 1. |

`Hashtag` is `{ id, tag, post_count }`.

## A2.2 Added endpoints

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/users/:username/tagged` | Posts the user is mentioned in. The profile has a Tagged tab and `mentions` already exists in the schema, so the endpoint should exist rather than the tab being cut. |
| GET | `/users/me/blocked` | The blocked-accounts list in Settings. Was otherwise unreachable, leaving the client to cache blocks on-device — which would be wrong on a second device. |

Both are cursor-paginated.

## A2.3 `Post` must carry its full context

The client's post card cannot render Space, Event or location chips unless `Post`
includes `space`, `event`, `location` and `mentions` as specified in §2. These are
**not** optional extras — they are how the standout features surface in the feed. Any
local client DTO omitting them is a defect to be removed during integration.

---

# Amendment 3 — 2026-09-20

Ratified after Spaces / Events / reports shipped.

## A3.1 `POST /reports` wire format

The request is `{ "post_id"?, "comment_id"?, "user_id"?, "reason" }` with exactly one
target. The response is `201 { "id": UUID, "status": "open" }`.

`IBUgramKit.ReportBody` currently uses `{ subject, subject_id, reason, detail }`. That
is a kit bug. The server accepts **both** shapes until the kit is aligned; new client
code must send the contract shape.

## A3.2 `Event.postId` is derived

The `events` table has no `post_id` column. Posts point at events (`posts.event_id`).
`Event.postId` on the wire is the oldest post with that `event_id`, or `null`. Do not
add a column.

## A3.3 Username availability is in the contract, missing from the kit

`GET /users/:username/available` (A1.4) is live on the server. `IBUgramKit.API.Users`
does not yet declare it. The server registered the path locally. The next kit pass
must add `API.Users.available(username:)` and a `{ "available": Bool }` DTO so the
client stops using a parallel `Endpoint`.

## A3.4 Notifications are raised through one service

Other features must not write `notifications` rows themselves. They call:

```
try await request.notifications.raise(kind, to: recipientId, from: actorId, subject:)
```

`subject` is `.post(id)`, `.comment(id)`, `.space(id)`, `.event(id)`, or `.none`.
Returns `nil` (and writes nothing) for self-actions and either-way blocks.

**`group_key`** is unique on `(recipient_id, group_key)`:
- with a subject: `{kind}:{entity}:{uuid}` (`like:post:{id}`, `reply:comment:{id}`)
- with `.none`: `{kind}:{yyyy-mm-dd}` UTC day bucket (`follow:2026-09-21`)

Message requests do not increment the inbox unread badge until accepted.
