# 006. Upgrade scanner AI from Haiku 4.5 to Sonnet 4.6

Date: 2026-05-13
Status: Accepted

## Context

PLAN.md §1 locked the model as Claude Haiku 4.5 for both vision and text
generation, chosen for cost (~$0.002 per scan) and speed.

Real-world testing on the live scanner surfaced repeated misidentification on
clearly-branded items:

- An YSL jacket with the YSL logo visible in the frame was confidently
  labelled `brand: "Disney"` (v1.1 prompt). Confidence 0.85.
- After tightening the prompt to v1.2 with explicit "trust only visible
  labels" language, the same jacket returned `brand: null` (correct
  outcome when the label isn't clearly readable), but the model also
  hedged on items it should be able to identify confidently.

Haiku 4.5 is good at general scene description but unreliable at reading
small text on garments — exactly the operation a reseller scanner depends
on. The v1.2 prompt got us to "honest null" but not to "correct brand."

## Decision

Bump the model behind `web/lib/ai.ts` from `anthropic/claude-haiku-4-5`
to `anthropic/claude-sonnet-4-6`. Same prompts, same gateway
(OpenRouter), same call shape. Use Sonnet for both Prompt 1 (vision
identification) and Prompt 3 (price synthesis) — the cost delta on the
text-only call is ~$0.001 and not worth the two-model complexity.

Update PLAN.md §1 and root `CLAUDE.md` to reflect the new model name.
Bump `docs/ai-prompts.md` header from "All prompts use
`claude-haiku-4-5`" accordingly. Prompt version constants stay at v1.2
/ v1.1 — the prompt content didn't change, only the model executing
them.

## Cost impact

- Haiku 4.5: ~$0.002 / scan
- Sonnet 4.6: ~$0.006 / scan (3x)

Combined with Apify comp lookups (~$0.04–$0.08 per cache miss) and the
3/IP/day rate limit, expected steady-state cost per active free-tool
user is still under a penny per scan after caching. Sustainable.

## Switch-back / further upgrade trigger

**Drop back to Haiku** when:
- After we have a real test set of 50 real reseller items per
  PLAN §11, Haiku hits ≥75% brand accuracy on a refined prompt or with
  multi-photo input. The DoD target is platform-wide accuracy; if we
  hit it on Haiku, switch back for the cost saving.

**Bump to Opus 4.7** when:
- Sonnet's accuracy on the same test set is also under 75% AND a
  manual review confirms the failures are vision-quality bound (small
  text, partial labels) rather than prompt-bound.

## Alternatives considered

- **Multi-photo on Haiku.** Architectural support for 1–6 photos is
  already in `docs/ai-prompts.md`. With a back-of-collar label shot,
  Haiku should be able to read the brand. Defers to follow-up — model
  swap is a single-line change for fast iteration; multi-photo is a
  larger UI/server change worth doing in the same week.
- **Multi-photo on Sonnet (both).** Best quality but premature. Get a
  reading on what Sonnet alone fixes first; multi-photo can land on
  top.
- **Smart routing: Haiku by default, escalate to Sonnet on low
  confidence.** Adds branching for a v1 cost optimisation; revisit
  with usage data.

## Consequences

- PLAN.md §1 and root CLAUDE.md updated in the same PR.
- Per-scan cost goes up 3x on the AI step.
- Latency goes up modestly (Sonnet is slower than Haiku, but still
  faster than Apify; total scan time dominated by Apify).
- All existing prompts work unchanged.
- Multi-photo is queued as the next accuracy lever if Sonnet alone
  doesn't get us to the DoD bar.
