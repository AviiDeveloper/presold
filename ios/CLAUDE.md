# Claude Code — iOS Context

You are working in the iOS app. Native SwiftUI, iOS 17+ minimum.

Before any work in this directory, also read:
- `../CLAUDE.md` (root)
- `../PLAN.md`
- `../docs/data-model.md` (for any work touching persistence)
- `../docs/ai-prompts.md` (for any AI integration)

## Conventions

### File organisation
- One type per file
- View + ViewModel pair lives in the same folder, named e.g. `CaptureView.swift` + `CaptureViewModel.swift`
- Services are singletons accessed via `ServiceName.shared` for now; we'll refactor to DI when the app exceeds 30 screens (it won't in v1)
- Models are plain structs, Codable where they cross the wire

### View patterns
- Use `@Observable` (iOS 17+) over `ObservableObject`
- Prefer `.task { ... }` over `.onAppear { Task { ... } }`
- Long-running work in ViewModels, not Views
- No business logic in Views — Views render, ViewModels decide

### State management
- Local UI state: `@State`
- Cross-view state: `@Observable` view models passed via initialiser
- App-wide state: `@Environment` (only for things like current user, never for transient state)

### Networking
- All Supabase calls through `SupabaseClient.shared`
- All Claude API calls through `AIService.shared` (which proxies through Supabase edge function, never directly from device)
- All eBay calls through Supabase edge function — never directly from device

### Error handling
- Network errors: surface as `Result<T, AppError>` to ViewModel
- Show user-friendly message via `@State var errorMessage: String?` pattern
- Log to Sentry in production

### Money math
- ALWAYS use `Decimal` for prices, fees, profits. Never `Double` or `Float`.
- All formatting through `CurrencyFormatter.gbp` (in Utilities)
- `PricingService` is the only place that calculates fees and profit. Tested.

### Concurrency
- Async/await throughout
- `@MainActor` on ViewModels by default
- Background work explicitly marked with `Task.detached` only when needed

## What lives where

| Folder | What goes here |
|---|---|
| `Models/` | Codable structs, enums, value types |
| `Services/` | Network, persistence, system integrations (camera, StoreKit) |
| `Views/` | SwiftUI views + view models |
| `Views/Components/` | Reusable UI building blocks |
| `Utilities/` | Pure functions, formatters, helpers |
| `Config/` | Environment configuration, never secrets |
| `Resources/` | Strings, fonts, assets references |

## What NOT to do in iOS code

- Don't store user credentials for Vinted/Depop/eBay. WKWebView holds
  the user's own login session; we never see passwords or tokens.
- Don't auto-submit listings without an explicit user tap inside the
  embedded WebView. Per ADR-007 App Store positioning, the user must
  always be the one to hit "Post."
- Don't call Anthropic or eBay APIs directly from the app — proxy
  through Supabase edge functions
- Don't use Combine — async/await throughout
- Don't add a routing library — NavigationStack is enough for v1
- Don't add a state management library — `@Observable` is enough for v1

## Cross-listing notes (ADR-007)

Cross-listing is in v1 (eBay native API + Vinted/Depop via WKWebView).
- eBay: OAuth flow via Supabase edge function, Sell Inventory API
- Vinted / Depop: WKWebView with JS form-fill, photo upload via JS bridge
  from `PHPickerViewController`. Per-platform automation modules live in
  `Services/CrossListing/`.
