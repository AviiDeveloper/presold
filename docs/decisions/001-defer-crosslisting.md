# 001. Defer cross-listing automation to v2

Date: 2026-05-13
Status: Accepted

## Context

Cross-listing automation (one-tap post to Vinted + Depop + eBay) is the headline value prop of competitors like Vendoo, List Perfectly, Crosslist. It is also the most technically fragile feature: Vinted and Depop have no public APIs, every UI change on those platforms breaks integration, and the App Store has rejected apps that primarily automate third-party websites in WebViews.

We considered three architectures:
- WKWebView automation inside the iOS app
- Server-side headless browsers
- Chrome extension companion

All three carry meaningful risk for v1.

## Decision

v1 ships **without** cross-listing automation. Instead:
- AI generates platform-specific listing copy for Vinted, Depop, eBay
- User taps copy-to-clipboard per platform
- User pastes into the platform's native app manually

v2 adds WKWebView-based automation for Vinted and Depop, eBay API for direct posting.

## Alternatives

- **Ship cross-listing in v1**: build slips by 2-3 weeks, launch is gated on the most fragile feature, App Store risk is non-zero, single bug can kill all credibility.
- **Ship server-side automation**: legal/operational sinkhole, platforms ban server IPs, GDPR exposure from storing third-party credentials.

## Consequences

- v1 launch is faster (saves ~2 weeks)
- Marketing positioning loses "one-tap everywhere" promise; reframed as "AI writes your listing in 30 seconds, copy to each platform"
- Retention may be lower than competitors because copy-paste friction remains
- v2 has a clear value-add to justify a price increase or feature gate
- App Store risk on v1 is essentially zero
