# eBay API Notes

## APIs we use

1. **Browse API** — find similar active listings (not used in v1)
2. **Marketplace Insights API** — sold comp data, last 90 days, this is the one we care about

## Marketplace Insights gotchas

- Requires production access, **not** sandbox. Sandbox returns empty comp arrays.
- Production access requires a real eBay account in good standing and an app submission. Allow 5-10 business days.
- Rate limits: 5 calls/second, 5,000/day on free tier. Cache aggressively.
- The "sold" filter requires `filter=conditionIds:{...}&filter=buyingOptions:{...}` syntax — read the docs carefully.

## Auth

OAuth 2.0 client credentials grant for application-level calls (sold comp lookup is application-level, not user-level).

```
POST https://api.ebay.com/identity/v1/oauth2/token
Authorization: Basic base64(EBAY_APP_ID:EBAY_CERT_ID)
grant_type=client_credentials&scope=https://api.ebay.com/oauth/api_scope
```

Token lasts 2 hours. Cache and refresh.

## Query strategy

For each item identification, we issue ONE query:
```
GET /buy/marketplace_insights/v1_beta/item_sales/search
  ?q={brand} {category} {size}
  &filter=conditionIds:{1500|3000|4000}        # used conditions
  &limit=50
  &marketplace_ids=EBAY_GB
```

If results sparse (<3), broaden by dropping size. If still sparse, drop brand. Mark `confidence` accordingly.

## Cache strategy

- Cache key: `sha256(query_string)`
- TTL: 24 hours
- Storage: Supabase `cache` table or Vercel KV (decide in week 1)

## Fallback if API approval delayed

Edge function scrapes eBay UK sold listings page with rotating User-Agents. Same query syntax in URL. Parse with cheerio in Deno edge runtime. Slower, fragile, but unblocks the v1 launch if eBay drags on approval.

Document this as a temporary measure in an ADR if you build it.
