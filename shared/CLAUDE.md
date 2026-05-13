# Claude Code — Shared Types Context

JSON schemas shared between iOS and web for AI prompt outputs and inter-service contracts.

## Why this exists

When iOS and web both consume the output of the same AI prompt or edge function, the schema should be defined once and consumed in both languages. This directory holds JSON Schema files that are the source of truth.

## Conventions

- One schema per file, named after the type
- Use JSON Schema draft 2020-12
- Each schema has a `$id`, `title`, `description`, and `$schema`
- Match exactly to the prompt output in `docs/ai-prompts.md`

## Files

- `item.schema.json` — Output of `identify-item`
- `listing.schema.json` — Output of platform reformatting
- `price-guidance.schema.json` — Output of price guidance
- `platform.schema.json` — Enum of platforms

## How to keep in sync

When you change a prompt output:
1. Update the prompt in `docs/ai-prompts.md` (bump version)
2. Update the schema here
3. Regenerate Swift types (manually for now) in `ios/PreSold/Models/`
4. Regenerate TypeScript types in `web/lib/types.ts`

Manual sync is fine in v1. If it becomes painful, add a codegen step in v2.
