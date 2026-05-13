import "server-only";
import Anthropic from "@anthropic-ai/sdk";
import type { EbayComp, Item, PriceGuidance } from "./types";

/**
 * Prompt versions. Keep in sync with `docs/ai-prompts.md`.
 * Stored on `items.ai_prompt_version` and `price_scans.item_data.prompt_version`
 * so we can A/B compare quality across versions.
 */
export const IDENTIFY_ITEM_PROMPT_VERSION = "v1.0";
export const PRICE_GUIDANCE_PROMPT_VERSION = "v1.0";

const MODEL = "claude-haiku-4-5";

let cached: Anthropic | null = null;
function client(): Anthropic {
  if (cached) return cached;
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error("Missing ANTHROPIC_API_KEY");
  cached = new Anthropic({ apiKey });
  return cached;
}

const SUPPORTED_IMAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

export type SupportedImageType =
  | "image/jpeg"
  | "image/png"
  | "image/webp"
  | "image/gif";

function assertImageType(mimeType: string): SupportedImageType {
  if (!SUPPORTED_IMAGE_TYPES.has(mimeType)) {
    throw new Error(`Unsupported image type: ${mimeType}`);
  }
  return mimeType as SupportedImageType;
}

/**
 * Extract the JSON object from a model response. Haiku usually returns clean
 * JSON when asked, but occasionally wraps it in prose or ```json fences. This
 * helper accepts a prefill — we send "{" as the first assistant token to force
 * a JSON object start, then prepend it back here.
 */
function parseJsonResponse<T>(rawText: string, prefill = "{"): T {
  const text = (prefill + rawText).trim();
  try {
    return JSON.parse(text) as T;
  } catch {
    // Fallback: take from first { to last }
    const first = text.indexOf("{");
    const last = text.lastIndexOf("}");
    if (first === -1 || last === -1 || last <= first) {
      throw new Error(`Model returned non-JSON: ${rawText.slice(0, 200)}`);
    }
    return JSON.parse(text.slice(first, last + 1)) as T;
  }
}

/**
 * Prompt 1 — identify item from one or more photos.
 * See `docs/ai-prompts.md` for the canonical prompt text.
 */
export async function identifyItem(input: {
  imageBase64: string;
  mimeType: string;
  userContext?: string | null;
}): Promise<Item> {
  const mediaType = assertImageType(input.mimeType);

  const system = [
    "You are a UK reseller's assistant. You look at photos of a second-hand item and identify it, then write listing copy.",
    "",
    "Be conservative. If you cannot tell the brand or size from the photos, return null for that field — never guess. UK resellers are punished for inaccurate listings.",
    "",
    "Always return valid JSON matching the schema. Never include commentary outside the JSON.",
  ].join("\n");

  const userText = [
    `Optional context from user (may be empty): ${input.userContext?.trim() || "(none)"}`,
    "",
    "Return JSON matching this schema:",
    "{",
    '  "title": "string, max 60 chars, sentence case, no clickbait",',
    '  "description": "string, 2-4 short paragraphs, factual, mention condition and any flaws visible",',
    '  "brand": "string or null",',
    '  "category": "string, broad category like \'Women\\\'s tops\' or \'Men\\\'s trainers\'",',
    '  "size": "string or null, UK sizing if clothing",',
    '  "color": "string, primary colour",',
    '  "condition": "one of: new_with_tags, new_without_tags, very_good, good, satisfactory",',
    '  "weight_grams_estimate": "integer, for shipping",',
    '  "confidence": "number 0-1, how sure you are about brand and category"',
    "}",
  ].join("\n");

  const response = await client().messages.create({
    model: MODEL,
    max_tokens: 1024,
    system,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: mediaType,
              data: input.imageBase64,
            },
          },
          { type: "text", text: userText },
        ],
      },
      { role: "assistant", content: "{" },
    ],
  });

  const block = response.content[0];
  if (!block || block.type !== "text") {
    throw new Error("Anthropic returned no text block");
  }
  return parseJsonResponse<Item>(block.text);
}

/**
 * Prompt 3 — price guidance synthesised from item + sold comps.
 * See `docs/ai-prompts.md` for the canonical prompt text.
 */
export async function suggestPrice(input: {
  item: Item;
  comps: EbayComp[];
}): Promise<PriceGuidance> {
  const system = [
    "You are a UK reseller pricing assistant. You receive an identified item and a list of recent sold comp prices from eBay. You return a price recommendation with reasoning.",
    "",
    "If comps are sparse (under 3) or have wide variance (>50% spread), say so honestly. Do not invent confidence you don't have.",
  ].join("\n");

  const userText = [
    "Item:",
    JSON.stringify(input.item, null, 2),
    "",
    "eBay sold comps (last 90 days):",
    JSON.stringify(input.comps, null, 2),
    "",
    "Return JSON:",
    "{",
    '  "price_low": "number, GBP, conservative quick-sale price",',
    '  "price_recommended": "number, GBP, balanced price",',
    '  "price_high": "number, GBP, patient-seller price",',
    '  "sell_speed_estimate": "one of: fast, medium, slow, uncertain",',
    '  "reasoning": "string, 1-2 sentences, cite the comp data",',
    '  "comp_count": "integer",',
    '  "confidence": "number 0-1"',
    "}",
  ].join("\n");

  const response = await client().messages.create({
    model: MODEL,
    max_tokens: 512,
    system,
    messages: [
      { role: "user", content: userText },
      { role: "assistant", content: "{" },
    ],
  });

  const block = response.content[0];
  if (!block || block.type !== "text") {
    throw new Error("Anthropic returned no text block");
  }
  return parseJsonResponse<PriceGuidance>(block.text);
}
