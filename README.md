# IBUgram

A closed social network for the International Burch University community. Only `@ibu.edu.ba` and `@stu.ibu.edu.ba` addresses can hold an account. Inside that boundary it is a photo feed, with profiles, follows, search, direct messages, Spaces, campus events, and a campus map.

## Layout

| Path | What it is |
| --- | --- |
| `ibugram-ios/` | SwiftUI app. iOS 18 minimum. Bundle id `ba.ibu.ibugram`. |
| `ibugram-server/` | Vapor 4 API, Fluent, PostgreSQL. |
| `IBUgramKit/` | Shared models and endpoint contract, compiled into the app and the server. |
| `docs/` | Product spec, API contract, data model, architecture notes, and the runbook. |

## Run it

PostgreSQL 14 on `127.0.0.1:5432`, role `sead`, database `ibugram_dev`. From `ibugram-server/`:

```bash
swift run App migrate
swift run App seed
swift run App serve --hostname 127.0.0.1 --port 8080
```

Open `ibugram-ios/ibugram.xcodeproj`, scheme `ibugram`, and run it in the simulator. Sign in as `amina.hodzic@stu.ibu.edu.ba` and copy the one-time code from the server log.

Step-by-step setup, environment variables, and the simulator destination are in [docs/30-RUNBOOK.md](docs/30-RUNBOOK.md).

## Tests

```bash
cd IBUgramKit && swift test
cd ibugram-server && swift test
```

iOS tests use the `ibugram` scheme in `ibugram-ios/ibugram.xcodeproj`.

## Docs

- [Product specification](docs/00-PRODUCT-SPEC.md)
- [API contract](docs/01-API-CONTRACT.md)
- [Data model](docs/10-DATA-MODEL.md)
- [iOS architecture](docs/11-IOS-ARCHITECTURE.md)
