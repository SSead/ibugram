# IBUgram — Engineering Standards

Every contributing agent reads this before writing a line of code. Code review
rejects work that violates it.

## 1. Comments

**The codebase is self-documenting. Comments are the exception, not the norm.**

Do not write:
- Comments that restate the code (`// increment the counter`)
- Section banners (`// MARK: - Helpers` is acceptable; ASCII art is not)
- File header blocks with author/date — Xcode's default template header is removed
- `// TODO` without an owner and a reason
- Commentary aimed at a reviewer (`// changed this to fix the bug`)

Write a comment only to record something the code genuinely cannot express: a
non-obvious external constraint, a protocol requirement, a deliberate deviation, or a
unit/invariant that is not visible from the types.

When tempted to explain a block, extract it into a named function instead. A good
function name replaces a paragraph.

## 2. Naming

- Names carry the meaning. `fetchFollowingFeed(after:)`, not `getData(c:)`.
- No abbreviations except universally understood ones (`id`, `url`, `http`).
- Booleans read as assertions: `isVerified`, `hasLiked`, `canModerate`.
- Types are nouns; methods are verb phrases; computed properties are nouns.
- Swift API Design Guidelines are binding.

## 3. Swift

- Swift 6 language mode, strict concurrency. Zero warnings is a merge requirement.
- `struct` by default. `final class` when reference semantics are required.
- `@Observable` for view models; never `ObservableObject` in new code.
- `async`/`await` everywhere; no completion handlers, no Combine in new code.
- Errors are typed enums conforming to `Error`; never throw `NSError` or strings.
- No force-unwraps, no `try!`, no `as!` outside tests.
- Dependencies enter through initializers or the environment, never via singletons
  reached from inside a type.
- Keep functions under ~40 lines and types under ~250 lines. Split, don't scroll.

## 4. SwiftUI

- One view per file; the file is named after the view.
- A `body` longer than ~40 lines is decomposed into subviews or `@ViewBuilder` computed
  properties.
- No business logic in `body`. View models own state and effects.
- All spacing, colour and typography come from the design system
  (`Theme`), never from literals scattered in views.
- Every interactive element has an accessibility label; every image has alt text.
- Every view has a `#Preview` that renders from fixture data without a network.

## 5. Server (Vapor)

- Controllers are thin: decode, authorize, delegate, encode. No SQL in controllers.
- Business logic lives in services; persistence lives in repositories.
- Every route is authenticated unless it appears on the documented public list.
- Every mutation validates its input through a `Validatable` DTO.
- Migrations are additive, reversible and never edited once committed.
- N+1 queries are a review failure; eager-load with `.with(...)`.

## 6. Testing

- Swift Testing (`@Test`, `#expect`) for new tests; XCTest only for UI tests.
- Server: every endpoint has at least a happy path and an authorization test,
  executed against a real PostgreSQL test database.
- Client: view models and services are unit tested against a mocked API client.
- Tests are named as sentences describing the behaviour, not `test1`.
- No test depends on another test's side effects or on wall-clock sleeps.

## 7. Git

Agents do **not** run git commands. The Project Owner commits on your behalf after
review. Leave the working tree clean of scratch files, `.orig`, `.bak` or
commented-out code.

## 8. Definition of done for a task

1. Code compiles with zero warnings.
2. Tests for the new behaviour exist and pass.
3. The feature is reachable from the UI (client) or documented in the contract (server).
4. No file contains a comment that a reader would find redundant.
5. You reported, in your final message, exactly what you changed and what you verified.
