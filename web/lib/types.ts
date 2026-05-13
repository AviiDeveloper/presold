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

/** Output of Prompt 1 (identify-item). See `docs/ai-prompts.md`. */
export type Item = {
  title: string;
  description: string;
  brand: string | null;
  category: string;
  size: string | null;
  color: string;
  condition: ItemCondition;
  weight_grams_estimate: number;
  confidence: number;
};

export type SellSpeed = "fast" | "medium" | "slow" | "uncertain";

/** Output of Prompt 3 (price guidance). See `docs/ai-prompts.md`. */
export type PriceGuidance = {
  price_low: number;
  price_recommended: number;
  price_high: number;
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
