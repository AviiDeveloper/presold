# 002. Native SwiftUI, not React Native

Date: 2026-05-13
Status: Accepted

## Context

Mobile-first product. Choice between:
- React Native (one codebase, iOS + Android)
- Native SwiftUI (iOS only)

## Decision

Native SwiftUI, iOS only for v1.

## Alternatives

- **React Native**: covers Android, but founder is already fluent in SwiftUI from prior projects; camera UX matters here and is harder to polish in RN; RN adds a dependency layer that breaks unpredictably.
- **Native Swift + native Android (Kotlin)**: doubles build time.

## Consequences

- Lose ~35% of UK reseller market (Android users) at launch
- Camera capture and photo UX is best-in-class on iOS
- Future Android port is a real cost; budget 3-4 weeks of off-time if we do it
- Plan to add Android in v3 if v2 traction justifies it
