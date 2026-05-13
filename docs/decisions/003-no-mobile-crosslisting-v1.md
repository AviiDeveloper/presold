# 003. Cross-listing deferred and copy-to-clipboard in v1

Date: 2026-05-13
Status: Accepted

## Context

Even with cross-listing deferred (see 001), we needed to decide how the user transfers AI-generated listing copy from our app to Vinted/Depop/eBay in v1.

## Decision

Per-platform copy-to-clipboard. Three buttons in the listing review screen (Vinted, Depop, eBay), each copies the platform-formatted listing to clipboard. User then opens the target platform's native app, paste into the title and description fields, attach photos manually for v1.

## Alternatives

- **Deep linking**: open Vinted/Depop/eBay app with pre-filled fields via URL scheme. Coverage is inconsistent (Vinted has no public deep link spec) and photos can't be pre-attached.
- **Share sheet integration**: technically possible, but UX is confusing for users who don't know which "share to" option to pick.

## Consequences

- v1 UX is "copy, switch app, paste, attach photos, post" — about 90 seconds per platform
- Still meaningfully faster than writing the listing from scratch
- Photos remain a friction point; users have to re-pick from camera roll in the target app
- v2 will fix all of this with WKWebView automation
