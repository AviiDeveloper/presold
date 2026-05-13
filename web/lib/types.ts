/**
 * Shared output types for prompts and inter-service contracts.
 * Source of truth: `shared/types/*.schema.json`. Keep this file in sync
 * manually until codegen is added (per `shared/CLAUDE.md`).
 */

export type Platform = "vinted" | "depop" | "ebay";

export type ItemCondition =
  | "new_with_tags"
  | "new_without_tags"
  | "very_good"
  | "good"
  | "satisfactory";

/**
 * Output of Prompt 1 (identify-item). See `docs/ai-prompts.md`.
 * Every identifiable field is nullable — Haiku returns nulls and
 * `confidence: 0` when the photo doesn't contain an identifiable item.
 * The UI short-circuits to an empty-state in that case.
 */
export type Item = {
  title: string | null;
  description: string | null;
  brand: string | null;
  category: string | null;
  size: string | null;
  color: string | null;
  condition: ItemCondition | null;
  weight_grams_estimate: number | null;
  confidence: number;
};

export type SellSpeed = "fast" | "medium" | "slow" | "uncertain";

/**
 * Output of Prompt 3 (price guidance). See `docs/ai-prompts.md`.
 * Prices are nullable for the "no identifiable item" + sparse-comps case.
 */
export type PriceGuidance = {
  price_low: number | null;
  price_recommended: number | null;
  price_high: number | null;
  sell_speed_estimate: SellSpeed;
  reasoning: string;
  comp_count: number;
  confidence: number;
};

/** Normalised sold-comp from eBay Marketplace Insights. */
export type EbayComp = {
  title: string;
  price_gbp: number;
  condition: string | null;
  sold_at: string | null;
  item_web_url: string | null;
};
