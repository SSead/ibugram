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

The schema is split across Figures 3.6–3.10. Each file shows keys only, so it can be exported at a size that fits one page.

## Files

- `01-figure-3-1-system-context.mmd` — Figure 3.1 System context
- `02-figure-3-2-use-cases-by-actor.mmd` — Figure 3.2 Use cases by actor
- `03-figure-3-3-client-layering.mmd` — Figure 3.3 Client layering
- `04-figure-3-4-client-class-diagram.mmd` — Figure 3.4 Client class diagram
- `05-figure-3-5-server-class-diagram.mmd` — Figure 3.5 Server class diagram
- `06-figure-3-6-identity-and-accounts.mmd` — Figure 3.6 Identity and accounts
- `07-figure-3-7-posts.mmd` — Figure 3.7 Posts
- `08-figure-3-8-campus.mmd` — Figure 3.8 Campus
- `09-figure-3-9-messages.mmd` — Figure 3.9 Messages
- `10-figure-3-10-notifications.mmd` — Figure 3.10 Notifications
- `11-figure-3-11-sequence-otp-sign-in.mmd` — Figure 3.11 Sequence — OTP sign-in
- `12-figure-3-12-sequence-post-creation-with-on-device-alt-text.mmd` — Figure 3.12 Sequence — post creation with on-device alt text
- `13-figure-3-13-sequence-realtime-message-delivery-over-websocket.mmd` — Figure 3.13 Sequence — realtime message delivery over WebSocket
- `14-figure-3-14-activity-feed-load-with-offline-fallback.mmd` — Figure 3.14 Activity — feed load with offline fallback
- `15-figure-3-15-component-package-diagram.mmd` — Figure 3.15 Component / package diagram
- `16-figure-3-16-navigation-map.mmd` — Figure 3.16 Navigation map
