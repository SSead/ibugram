# IBUgram — Runbook

How to start PostgreSQL, load the campus demo dataset, run the Vapor server on
port 8080, and point the iOS simulator at it.

## Prerequisites

- PostgreSQL 14+ listening on `127.0.0.1:5432`
- Role `sead` with login (peer/trust on localhost is enough; no password in development)
- Database `ibugram_dev`
- Xcode 26 with the `iPhone 17 Pro` simulator (iOS 26.3.1)
- Swift 6 toolchain (the one Xcode ships)

Do not drop `ibugram_test*` databases. Those belong to the server test suites.

## 1. PostgreSQL

If the server is not already running:

```
brew services start postgresql@14
```

Create the development database once:

```
createdb -h 127.0.0.1 -U sead ibugram_dev
```

`createdb` is a no-op if the database already exists (`ERROR: database "ibugram_dev" already exists`).

## 2. Migrate

From `ibugram-server/`:

```
cd ibugram-server
swift run App migrate
```

The process always auto-migrates on boot as well, so `swift run App serve` and
`swift run App seed` will apply any missing migrations before they do their own work.
`migrate` is the command to run when you only want the schema.

## 3. Seed the campus dataset

```
cd ibugram-server
swift run App seed
```

This is idempotent: a second run deletes the previous seed users (and everything that
cascades from them) and inserts the same campus dataset again. It does not truncate
unrelated rows.

The command prints the demo emails. Authentication is passwordless OTP — request a
code in the app, then read it from the server log (development only).

Primary demo user:

```
amina.hodzic@stu.ibu.edu.ba
```

Faculty accounts use `@ibu.edu.ba` and carry the verified badge. Students use
`@stu.ibu.edu.ba`.

Solid-color JPEG stand-ins are written into the media directory
(`.media/` under `ibugram-server/` unless `MEDIA_DIRECTORY` is set).

## 4. Run the API

```
cd ibugram-server
swift run App serve --hostname 127.0.0.1 --port 8080
```

Health check: `curl http://127.0.0.1:8080/health`.

The iOS development client is hard-wired to that origin
(`APIConfiguration.development`).

## 5. iOS simulator

Open `ibugram-ios/ibugram.xcodeproj`, scheme `ibugram`, destination
**iPhone 17 Pro (iOS 26.3.1)**. Run from Xcode, or:

```
cd ibugram-ios
xcodebuild -project ibugram.xcodeproj -scheme ibugram \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' \
  build
```

The `OS=` component is required. Without it `xcodebuild` resolves iOS 27.0, which has
no `iPhone 17 Pro` device.

Sign in as `amina.hodzic@stu.ibu.edu.ba`, request an OTP, and copy the six-digit
code from the Vapor console.

Siri / Shortcuts intents live in the main app target:

- “What's happening at Burch?”
- “Post to IBUgram”

There is no WidgetKit extension. Adding one needs a new native target and a
`project.pbxproj` edit; this project uses synchronized file groups, so that surgery
is deferred.

## Environment overrides

| Variable | Default |
| --- | --- |
| `DATABASE_HOST` | `127.0.0.1` |
| `DATABASE_PORT` | `5432` |
| `DATABASE_USERNAME` | `sead` |
| `DATABASE_NAME` | `ibugram_dev` (or `ibugram_test` when `ENVIRONMENT=testing`) |
| `MEDIA_DIRECTORY` | `./.media` |
| `PUBLIC_BASE_URL` | `http://127.0.0.1:8080` |
| `JWT_SECRET` | development placeholder (required in production) |
