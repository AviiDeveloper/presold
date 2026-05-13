import "server-only";
import { createHash } from "node:crypto";
import type { EbayComp, Item } from "./types";

/**
 * eBay Marketplace Insights wrapper.
 *
 * - OAuth 2.0 client_credentials grant, token cached for ~2h.
 * - Per-query 24h cache in-process. PLAN §8 specifies "cache comp data per
 *   (item_category, query) for 24h" — we hash the full query string so
 *   identical queries hit cache, and the IP rate limit (3/IP/day) keeps the
 *   working set tiny enough that a Map is fine for v1.
 * - If credentials are absent OR a request fails, return [] and let the
 *   downstream prompt note "comps sparse". The free scanner is still useful
 *   without comps; we don't want a missing eBay key to break the whole flow.
 *
 * If we move past serverless, replace the in-memory cache with Vercel KV or
 * a Supabase `cache` table — see docs/ebay-api-notes.md.
 */

type EbayEnv = "PRODUCTION" | "SANDBOX";

const TOKEN_TTL_MS = 110 * 60 * 1000; // 110 min; eBay says 2h
const COMP_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_RESULTS = 50;
const MIN_USEFUL_COMPS = 3;

const compCache = new Map<string, { comps: EbayComp[]; expiresAt: number }>();
let tokenCache: { token: string; expiresAt: number } | null = null;

function env(): EbayEnv {
  return process.env.EBAY_ENV === "SANDBOX" ? "SANDBOX" : "PRODUCTION";
}

function baseUrl() {
  return env() === "SANDBOX"
    ? "https://api.sandbox.ebay.com"
    : "https://api.ebay.com";
}

function credentials() {
  const appId = process.env.EBAY_APP_ID;
  const certId = process.env.EBAY_CERT_ID;
  if (!appId || !certId) return null;
  return { appId, certId };
}

async function getAppToken(): Promise<string | null> {
  const creds = credentials();
  if (!creds) return null;

  const now = Date.now();
  if (tokenCache && tokenCache.expiresAt > now) return tokenCache.token;

  const basic = Buffer.from(`${creds.appId}:${creds.certId}`).toString(
    "base64",
  );
  const res = await fetch(`${baseUrl()}/identity/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body:
      "grant_type=client_credentials&scope=" +
      encodeURIComponent("https://api.ebay.com/oauth/api_scope"),
    cache: "no-store",
  });

  if (!res.ok) {
    console.error(
      "[ebay] token fetch failed",
      res.status,
      await res.text().catch(() => ""),
    );
    return null;
  }

  const data = (await res.json()) as { access_token?: string };
  if (!data.access_token) return null;

  tokenCache = { token: data.access_token, expiresAt: now + TOKEN_TTL_MS };
  return data.access_token;
}

function buildQuery(item: Item, opts: { dropSize: boolean; dropBrand: boolean }) {
  const parts: string[] = [];
  if (!opts.dropBrand && item.brand) parts.push(item.brand);
  if (item.category) parts.push(item.category);
  if (!opts.dropSize && item.size) parts.push(item.size);
  if (item.color) parts.push(item.color);
  return parts.join(" ").trim();
}

function cacheKey(query: string) {
  return createHash("sha256").update(query).digest("hex");
}

async function searchSales(
  q: string,
  token: string,
): Promise<EbayComp[] | null> {
  const url = new URL(
    `${baseUrl()}/buy/marketplace_insights/v1_beta/item_sales/search`,
  );
  url.searchParams.set("q", q);
  // 1500=New other, 3000=Used, 4000=Very Good — typical used-condition spread
  url.searchParams.set("filter", "conditionIds:{1500|3000|4000}");
  url.searchParams.set("limit", String(MAX_RESULTS));

  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      "X-EBAY-C-MARKETPLACE-ID": "EBAY_GB",
      Accept: "application/json",
    },
    cache: "no-store",
  });

  if (!res.ok) {
    console.error(
      "[ebay] insights fetch failed",
      res.status,
      await res.text().catch(() => ""),
    );
    return null;
  }

  const data = (await res.json()) as {
    itemSales?: Array<{
      title?: string;
      lastSoldPrice?: { value?: string; currency?: string };
      condition?: string;
      lastSoldDate?: string;
      itemWebUrl?: string;
    }>;
  };

  const comps: EbayComp[] = (data.itemSales ?? [])
    .map((sale) => {
      const value = Number(sale.lastSoldPrice?.value);
      const currency = sale.lastSoldPrice?.currency;
      if (!Number.isFinite(value) || currency !== "GBP") return null;
      return {
        title: sale.title ?? "",
        price_gbp: value,
        condition: sale.condition ?? null,
        sold_at: sale.lastSoldDate ?? null,
        item_web_url: sale.itemWebUrl ?? null,
      } satisfies EbayComp;
    })
    .filter((c): c is EbayComp => c !== null);

  return comps;
}

/**
 * Look up sold comps for an item. Tries the full query, broadens by dropping
 * size if results are sparse, then drops brand. Returns whatever we have.
 *
 * Returns [] (with no error) when:
 * - eBay credentials are not configured
 * - the OAuth token fetch fails
 * - the insights API fails on every broadening step
 *
 * The downstream price-guidance prompt treats sparse comps as "low confidence"
 * rather than failing the whole scan.
 */
export async function fetchSoldComps(item: Item): Promise<EbayComp[]> {
  const token = await getAppToken();
  if (!token) return [];

  const tiers: Array<{ dropSize: boolean; dropBrand: boolean }> = [
    { dropSize: false, dropBrand: false },
    { dropSize: true, dropBrand: false },
    { dropSize: true, dropBrand: true },
  ];

  let best: EbayComp[] = [];
  for (const tier of tiers) {
    const query = buildQuery(item, tier);
    if (!query) continue;

    const key = cacheKey(query);
    const cached = compCache.get(key);
    if (cached && cached.expiresAt > Date.now()) {
      best = cached.comps;
    } else {
      const comps = await searchSales(query, token);
      if (comps === null) continue;
      compCache.set(key, {
        comps,
        expiresAt: Date.now() + COMP_TTL_MS,
      });
      best = comps;
    }

    if (best.length >= MIN_USEFUL_COMPS) return best;
  }

  return best;
}
