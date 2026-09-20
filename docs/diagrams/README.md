# Mermaid diagrams for the SDP

These files are copied from `Senior Design Project.md` (Chapter 3).
Export each to PNG, then insert the PNG in Google Docs in place of the code block.

## Export (easiest)

1. Open https://mermaid.live
2. Paste the contents of one `.mmd` file
3. Actions → PNG (or SVG)
4. Save as the same stem, e.g. `01-figure-31-system-context.png`

If you have Node:

```
npx -y @mermaid-js/mermaid-cli -i 01-figure-31-system-context.mmd -o 01-figure-31-system-context.png
```

The entity-relationship diagram (`06-…`) is large. If mermaid.live times out, use SVG instead of PNG, or export at 2× scale.

## Files

- `01-figure-3-1-system-context.mmd` — Figure 3.1 System context (22 lines)
- `02-figure-3-2-use-cases-by-actor.mmd` — Figure 3.2 Use cases by actor (32 lines)
- `03-figure-3-3-client-layering.mmd` — Figure 3.3 Client layering (60 lines)
- `04-figure-3-4-client-class-diagram.mmd` — Figure 3.4 Client class diagram (53 lines)
- `05-figure-3-5-server-class-diagram.mmd` — Figure 3.5 Server class diagram (65 lines)
- `06-figure-3-6-entity-relationship-diagram.mmd` — Figure 3.6 Entity-relationship diagram (378 lines)
- `07-figure-3-7-sequence-otp-sign-in.mmd` — Figure 3.7 Sequence — OTP sign-in (31 lines)
- `08-figure-3-8-sequence-post-creation-with-on-device-alt-text.mmd` — Figure 3.8 Sequence — post creation with on-device alt text (30 lines)
- `09-figure-3-9-sequence-realtime-message-delivery-over-websocket.mmd` — Figure 3.9 Sequence — realtime message delivery over WebSocket (17 lines)
- `10-figure-3-10-activity-feed-load-with-offline-fallback.mmd` — Figure 3.10 Activity — feed load with offline fallback (18 lines)
- `11-figure-3-11-component-package-diagram.mmd` — Figure 3.11 Component / package diagram (13 lines)
- `12-figure-3-12-navigation-map.mmd` — Figure 3.12 Navigation map (22 lines)
