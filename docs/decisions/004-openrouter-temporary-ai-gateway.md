# 004. Route AI calls through OpenRouter temporarily

Date: 2026-05-13
Status: Accepted (temporary)

## Context

PLAN.md §1 names Claude Haiku 4.5 (`claude-haiku-4-5`) as the only AI model and the supabase/CLAUDE.md guidance says `ANTHROPIC_API_KEY` is the only AI provider. The intent there is "one model, one provider" — not "the SDK must be `@anthropic-ai/sdk` specifically".

Direct Anthropic API billing isn't live on the project account yet. We have $5 of prepaid OpenRouter credit available immediately, which is enough to exercise the Week 1 scanner end-to-end for testing and the first few real scans.

## Decision

Route the Week 1 scanner's vision and price-guidance calls through
**OpenRouter**, targeting the same model (`anthropic/claude-haiku-4-5`) via its
OpenAI-compatible `/api/v1/chat/completions` endpoint. Removed
`@anthropic-ai/sdk` from `web/package.json`; the AI client (`web/lib/ai.ts`)
uses plain `fetch` against OpenRouter.

Env var: `OPEN_ROUTER_API_KEY` (server-side only). Model identifier stays as
Haiku 4.5.

## Switch-back trigger

Switch to **Anthropic direct** when:

- Anthropic billing is enabled on the project account, AND
- We have enough usage signal from real scans to justify removing the
  per-request OpenRouter margin (~5%), OR
- OpenRouter introduces a meaningful latency / rate-limit issue at our volume.

The switch is a small refactor: re-introduce `@anthropic-ai/sdk`, replace the
`chat()` fetch helper in `web/lib/ai.ts` with the SDK's `messages.create()`,
swap `image_url` content blocks back to Anthropic's `image` blocks, drop the
`OPEN_ROUTER_API_KEY` env in favour of `ANTHROPIC_API_KEY`. Prompt content
stays identical because we maintained the prompt text + version stamps.

## Alternatives considered

- **Wait for Anthropic billing approval.** Blocks Week 1 D3-4 testing
  indefinitely. Unacceptable when the scanner is the top-of-funnel asset for
  Week 1's first TikTok.
- **Support both via a runtime switch** (`if (process.env.ANTHROPIC_API_KEY) {
  useAnthropic } else { useOpenRouter }`). Adds branching for a temporary
  state. Cheaper to just flip when billing lands.
- **Keep `@anthropic-ai/sdk` installed alongside the fetch path.** Dead
  dependency; CLAUDE.md prefers removal of unused code.

## Consequences

- One vendor between us and Haiku for the testing period. Negligible latency
  cost (<100ms typically).
- ~5% margin paid to OpenRouter on each call until switch-back.
- OpenAI-compatible image format (`image_url` with data URL) means the
  Anthropic native `image` block format is not exercised until switch-back —
  smoke-test the vision path after the switch.
- Prompt prefill (`{` as assistant token) doesn't work cleanly via OpenRouter's
  chat-completions shape; we now rely on stronger instruction text + the
  defensive JSON extractor in `parseJsonResponse`.
- All other AI references in the codebase (prompts, version stamps,
  `docs/ai-prompts.md`) are gateway-agnostic and need no change at switch-back.
