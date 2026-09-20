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
