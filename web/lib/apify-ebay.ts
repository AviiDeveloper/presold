import "server-only";
import { createHash } from "node:crypto";
import type { EbayComp, Item } from "./types";

/**
 * eBay sold comps via Apify (temporary; see ADR-005).
 *
 * Hits the `caffein.dev/ebay-sold-listings` actor synchronously via Apify's
 * `/run-sync-get-dataset-items` REST endpoint — no polling, returns the
 * full dataset in one HTTP round trip.
 *
 * Caching + broaden-on-sparse mirrors `lib/ebay.ts` so the two can be
 * swapped without changing `lib/scan.ts`'s call shape.
 *
 * Returns [] gracefully when `APIFY_TOKEN` is missing or the actor errors,
 * so the scan flow still ships a result (Haiku flags low confidence).
 */

const ACTOR_ID = "caffein.dev~ebay-sold-listings"; // Apify URL form uses ~
const APIFY_URL = `https://api.apify.com/v2/acts/${ACTOR_ID}/run-sync-get-dataset-items`;

const COMP_TTL_MS = 24 * 60 * 60 * 1000;
// 12 comps anchors a reliable price recommendation and trims Apify runtime
// by ~30% vs. 20 — meaningful for the on-the-go charity-shop flow.
const MAX_RESULTS = 12;
const ACTOR_TIMEOUT_S = 60; // Actor terminates after this even if mid-fetch

type ApifyItem = {
  title?: string;
  soldPrice?: string;
  soldCurrency?: string;
  endedAt?: string;
  url?: string;
};

const compCache = new Map<string, { comps: EbayComp[]; expiresAt: number }>();

function apifyToken(): string | null {
  return process.env.APIFY_TOKEN || null;
}

function buildKeyword(
  item: Item,
  opts: { dropSize: boolean; dropBrand: boolean },
) {
  const parts: string[] = [];
  if (!opts.dropBrand && item.brand) parts.push(item.brand);
  if (item.category) parts.push(item.category);
  if (!opts.dropSize && item.size) parts.push(item.size);
  if (item.color) parts.push(item.color);
  return parts.join(" ").trim();
}

function cacheKey(keyword: string) {
  return createHash("sha256").update(keyword).digest("hex");
}

async function runActor(
  keyword: string,
  token: string,
): Promise<EbayComp[] | null> {
  const url = `${APIFY_URL}?token=${encodeURIComponent(token)}&timeout=${ACTOR_TIMEOUT_S}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      keywords: [keyword],
      ebaySite: "ebay.co.uk",
      count: MAX_RESULTS,
      daysToScrape: 90,
      sortOrder: "endedRecently",
    }),
    cache: "no-store",
  });

  if (!res.ok) {
    console.error(
      "[apify] ebay-sold actor failed",
      res.status,
      await res.text().catch(() => ""),
    );
    return null;
  }

  const items = (await res.json()) as ApifyItem[];
  if (!Array.isArray(items)) return null;

  const comps: EbayComp[] = items
    .map((sale): EbayComp | null => {
      const price = Number(sale.soldPrice);
      if (!Number.isFinite(price) || price <= 0) return null;
      if (sale.soldCurrency && sale.soldCurrency !== "GBP") return null;
      return {
        title: sale.title ?? "",
        price_gbp: price,
        // detailedSearch disabled to keep cost/latency down; condition
        // unknown at the comp level (ADR-005).
        condition: null,
        sold_at: sale.endedAt ?? null,
        item_web_url: sale.url ?? null,
      };
    })
    .filter((c): c is EbayComp => c !== null);

  return comps;
}

export async function fetchSoldCompsViaApify(item: Item): Promise<EbayComp[]> {
  const token = apifyToken();
  if (!token) return [];

  // Single-tier query. Broaden-on-sparse used to drop size/brand and retry,
  // but each Apify run is 30s+ on cold start — three sequential tiers blew
  // Vercel's 60s function ceiling and the request returned no body. The
  // price-guidance prompt already handles sparse comps as "low confidence"
  // and recommends `null` prices, so a single honest query beats a stack of
  // broadening retries that timeout before any of them write to the DB.
  const keyword = buildKeyword(item, { dropSize: false, dropBrand: false });
  if (!keyword) return [];

  const key = cacheKey(keyword);
  const cached = compCache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.comps;

  const comps = await runActor(keyword, token);
  if (comps === null) return [];

  compCache.set(key, { comps, expiresAt: Date.now() + COMP_TTL_MS });
  return comps;
}
