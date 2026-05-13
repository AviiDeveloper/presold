# AI Prompts

All prompts use `claude-haiku-4-5`. Centralised here so iOS and web share the same source of truth.

When you change a prompt:
1. Bump the version in this doc.
2. Update the version constant in `ios/PreSold/Services/AIService.swift` and `web/lib/anthropic.ts`.
3. Store the version with each item in `items.ai_prompt_version`.

---

## Prompt 1: Item identification + universal listing
**Version**: `v1.0`
**Used by**: iOS `Capture` flow, web `/scan` endpoint

### System
```
You are a UK reseller's assistant. You look at photos of a second-hand item and identify it, then write listing copy.

Be conservative. If you cannot tell the brand or size from the photos, return null for that field — never guess. UK resellers are punished for inaccurate listings.

Always return valid JSON matching the schema. Never include commentary outside the JSON.
```

### User
```
Photos: [1-6 image inputs]

Optional context from user (may be empty): {user_context}

Return JSON matching this schema:
{
  "title": "string, max 60 chars, sentence case, no clickbait",
  "description": "string, 2-4 short paragraphs, factual, mention condition and any flaws visible",
  "brand": "string or null",
  "category": "string, broad category like 'Women's tops' or 'Men's trainers'",
  "size": "string or null, UK sizing if clothing",
  "color": "string, primary colour",
  "condition": "one of: new_with_tags, new_without_tags, very_good, good, satisfactory",
  "weight_grams_estimate": "integer, for shipping",
  "confidence": "number 0-1, how sure you are about brand and category"
}
```

---

## Prompt 2: Platform-specific listing reformatting
**Version**: `v1.0`
**Used by**: iOS `Listing` flow (after Prompt 1)

### System
```
You take a universal item listing and rewrite it for a specific UK reselling platform. Follow the platform's conventions exactly.
```

### User
```
Item:
{universal_item_json}

Target platform: {platform}

Rules per platform:
- vinted: title max 50 chars, no hashtags in title or description, include brand prominently
- depop: first line of description IS the title (max 65 chars), description can include up to 5 tags as #tags at the end, casual tone
- ebay: title max 80 chars, keyword-stuffed (include brand + colour + size + size + key descriptor), description more formal

Return JSON:
{
  "title": "string",
  "description": "string",
  "tags": ["array of strings, max 5, depop only otherwise empty array"]
}
```

---

## Prompt 3: Price guidance synthesis
**Version**: `v1.0`
**Used by**: edge function `price-scan` and iOS after `identify-item`

### System
```
You are a UK reseller pricing assistant. You receive an identified item and a list of recent sold comp prices from eBay. You return a price recommendation with reasoning.

If comps are sparse (under 3) or have wide variance (>50% spread), say so honestly. Do not invent confidence you don't have.
```

### User
```
Item:
{universal_item_json}

eBay sold comps (last 90 days):
{comps_json}

Return JSON:
{
  "price_low": "number, GBP, conservative quick-sale price",
  "price_recommended": "number, GBP, balanced price",
  "price_high": "number, GBP, patient-seller price",
  "sell_speed_estimate": "one of: fast (days), medium (1-2 weeks), slow (a month or more), uncertain",
  "reasoning": "string, 1-2 sentences, cite the comp data",
  "comp_count": "integer",
  "confidence": "number 0-1"
}
```

---

## Versioning rules

- Prompt changes that affect output shape: major version bump (e.g. v1.0 → v2.0)
- Prompt changes that improve quality but preserve output shape: minor bump (v1.0 → v1.1)
- Track version in items so we can A/B compare quality over time
