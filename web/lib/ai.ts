import "server-only";
import type { EbayComp, Item, PriceGuidance } from "./types";

/**
 * AI gateway — currently routed through OpenRouter to `anthropic/claude-haiku-4-5`.
 *
 * Why OpenRouter (temporary): Anthropic direct billing isn't enabled yet on the
 * project account; OpenRouter gives us prepaid access to the same Haiku model
 * via an OpenAI-compatible endpoint for the cost of the credits already loaded.
 * See `docs/decisions/004-openrouter-temporary-ai-gateway.md` for the plan to
 * switch back to direct Anthropic once billing is live.
 *
 * Prompt versions stay in sync with `docs/ai-prompts.md`; the model and gateway
 * are config, the prompts are content.
 */

export const IDENTIFY_ITEM_PROMPT_VERSION = "v1.2";
export const PRICE_GUIDANCE_PROMPT_VERSION = "v1.1";

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
// Bumped from Haiku to Sonnet for vision-reading accuracy (label/logo OCR).
// See docs/decisions/006-sonnet-for-vision.md
const MODEL = "anthropic/claude-sonnet-4-6";

const SUPPORTED_IMAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

function assertImageType(mimeType: string): string {
  if (!SUPPORTED_IMAGE_TYPES.has(mimeType)) {
    throw new Error(`Unsupported image type: ${mimeType}`);
  }
  return mimeType;
}

function apiKey(): string {
  const key = process.env.OPEN_ROUTER_API_KEY;
  if (!key) throw new Error("Missing OPEN_ROUTER_API_KEY");
  return key;
}

type OpenAiContent =
  | { type: "text"; text: string }
  | { type: "image_url"; image_url: { url: string } };

type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string | OpenAiContent[];
};

type ChatResponse = {
  choices?: Array<{ message?: { content?: string } }>;
  error?: { message?: string };
};

async function chat(
  messages: ChatMessage[],
  maxTokens: number,
): Promise<string> {
  const res = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey()}`,
      "Content-Type": "application/json",
      // Optional OpenRouter analytics headers — surface our usage on the
      // OpenRouter dashboard. Not sensitive.
      "HTTP-Referer": "https://presold.app",
      "X-Title": "PreSold",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: maxTokens,
      temperature: 0.2,
      messages,
    }),
    cache: "no-store",
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`OpenRouter HTTP ${res.status}: ${text.slice(0, 300)}`);
  }
  const body = (await res.json()) as ChatResponse;
  if (body.error) {
    throw new Error(`OpenRouter error: ${body.error.message ?? "unknown"}`);
  }
  const content = body.choices?.[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new Error("OpenRouter returned empty content");
  }
  return content;
}

/**
 * Extract a JSON object from a model response. Haiku usually returns clean
 * JSON when instructed; falls back to grabbing the first { ... last }.
 */
function parseJsonResponse<T>(rawText: string): T {
  const text = rawText.trim();
  try {
    return JSON.parse(text) as T;
  } catch {
    const first = text.indexOf("{");
    const last = text.lastIndexOf("}");
    if (first === -1 || last === -1 || last <= first) {
      throw new Error(`Model returned non-JSON: ${rawText.slice(0, 200)}`);
    }
    return JSON.parse(text.slice(first, last + 1)) as T;
  }
}

/** Prompt 1 — identify item from a photo. See `docs/ai-prompts.md`. */
export async function identifyItem(input: {
  imageBase64: string;
  mimeType: string;
  userContext?: string | null;
}): Promise<Item> {
  const mediaType = assertImageType(input.mimeType);
  const dataUrl = `data:${mediaType};base64,${input.imageBase64}`;

  const system = [
    "You are a UK reseller's assistant. You look at photos of a second-hand item and identify it, then write listing copy.",
    "",
    "Be conservative. If you cannot tell the brand or size from the photos, return null for that field — never guess. UK resellers are punished for inaccurate listings.",
    "",
    "Brand identification rule: identify the brand only from visible brand labels, woven neck/care tags, hangtags, printed logos, or embossed brand marks. Do NOT infer the brand from cut, silhouette, typography on a graphic, colourway, or because the item resembles a famous brand's style. If no brand mark is legible in any photo, return brand: null. UK reselling marketplaces (Vinted, Depop, eBay UK) issue penalties — including bans — for misidentified counterfeits and dupes. Null is safer than wrong.",
    "",
    "Size identification rule: only trust a visible size label or care tag. Never estimate size from item proportions or model implications.",
    "",
    "If the photo contains no identifiable resellable item at all, return every identifiable field as null and confidence: 0. Do not invent placeholder values.",
    "",
    "Respond with ONLY a valid JSON object matching the schema. No prose, no code fences, no commentary.",
  ].join("\n");

  const userText = [
    `Optional context from user (may be empty): ${input.userContext?.trim() || "(none)"}`,
    "",
    "Return JSON matching this schema:",
    "{",
    '  "title": "string or null, max 60 chars, sentence case, no clickbait",',
    '  "description": "string or null, 2-4 short paragraphs, factual, mention condition and any flaws visible",',
    '  "brand": "string or null",',
    '  "category": "string or null, broad category like \'Women\\\'s tops\' or \'Men\\\'s trainers\'",',
    '  "size": "string or null, UK sizing if clothing",',
    '  "color": "string or null, primary colour",',
    '  "condition": "string or null — one of: new_with_tags, new_without_tags, very_good, good, satisfactory (null only if you can\\\'t identify the item at all)",',
    '  "weight_grams_estimate": "integer or null, grams for shipping",',
    '  "confidence": "number 0-1, how sure you are about brand and category (0 if no item visible)"',
    "}",
  ].join("\n");

  const content = await chat(
    [
      { role: "system", content: system },
      {
        role: "user",
        content: [
          { type: "image_url", image_url: { url: dataUrl } },
          { type: "text", text: userText },
        ],
      },
    ],
    1024,
  );

  return parseJsonResponse<Item>(content);
}

/** Prompt 3 — price guidance from item + sold comps. See `docs/ai-prompts.md`. */
export async function suggestPrice(input: {
  item: Item;
  comps: EbayComp[];
}): Promise<PriceGuidance> {
  const system = [
    "You are a UK reseller pricing assistant. You receive an identified item and a list of recent sold comp prices from eBay. You return a price recommendation with reasoning.",
    "",
    "If comps are sparse (under 3) or have wide variance (>50% spread), say so honestly. Do not invent confidence you don't have.",
    "",
    "If the item couldn't be identified (all identifiable fields null) or comps are too sparse to anchor a recommendation, return null for the three price fields and confidence: 0.",
    "",
    "Respond with ONLY a valid JSON object. No prose, no code fences, no commentary.",
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
    '  "price_low": "number or null, GBP, conservative quick-sale price",',
    '  "price_recommended": "number or null, GBP, balanced price",',
    '  "price_high": "number or null, GBP, patient-seller price",',
    '  "sell_speed_estimate": "one of: fast, medium, slow, uncertain",',
    '  "reasoning": "string, 1-2 sentences, cite the comp data (or note why no price could be given)",',
    '  "comp_count": "integer",',
    '  "confidence": "number 0-1"',
    "}",
  ].join("\n");

  const content = await chat(
    [
      { role: "system", content: system },
      { role: "user", content: userText },
    ],
    512,
  );

  return parseJsonResponse<PriceGuidance>(content);
}
