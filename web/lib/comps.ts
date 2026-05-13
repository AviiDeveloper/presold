import "server-only";
import { fetchSoldComps as fetchSoldCompsOfficial } from "./ebay";
import { fetchSoldCompsViaApify } from "./apify-ebay";
import type { EbayComp, Item } from "./types";

/**
 * Router between comp sources. While `APIFY_TOKEN` is set, route through
 * Apify (ADR-005); otherwise fall back to the official eBay Marketplace
 * Insights client (`lib/ebay.ts`). Switch-back is just removing the env
 * var — no code change needed.
 *
 * Both providers normalise to `EbayComp[]` and return [] on failure so
 * the scan flow keeps shipping a result with low-confidence guidance.
 */
export async function fetchSoldComps(item: Item): Promise<EbayComp[]> {
  if (process.env.APIFY_TOKEN) {
    return fetchSoldCompsViaApify(item);
  }
  return fetchSoldCompsOfficial(item);
}
