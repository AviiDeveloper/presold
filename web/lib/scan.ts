import "server-only";
import { randomUUID } from "node:crypto";
import { supabaseAdmin } from "./supabase";
import {
  IDENTIFY_ITEM_PROMPT_VERSION,
  PRICE_GUIDANCE_PROMPT_VERSION,
  identifyItem,
  suggestPrice,
} from "./anthropic";
import { fetchSoldComps } from "./ebay";
import { takeScanSlot } from "./rate-limit";
import type { EbayComp, Item, PriceGuidance } from "./types";

const MAX_PHOTO_BYTES = 10 * 1024 * 1024; // 10 MB
const SUPPORTED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

export type ScanError =
  | { code: "rate_limited"; resetAt: number }
  | { code: "missing_photo" }
  | { code: "photo_too_large" }
  | { code: "unsupported_image" }
  | { code: "ai_failed" }
  | { code: "server_error" };

export type ScanResult = {
  slug: string;
  item: Item;
  guidance: PriceGuidance;
  comp_count: number;
  photo_url: string;
};

export type ScanOutcome =
  | { ok: true; data: ScanResult }
  | { ok: false; error: ScanError };

export type ScanInput = {
  photo: File;
  userContext?: string | null;
  ipAddress: string | null;
};

function extFor(mime: string): string {
  if (mime === "image/jpeg") return "jpg";
  if (mime === "image/png") return "png";
  if (mime === "image/webp") return "webp";
  if (mime === "image/gif") return "gif";
  return "bin";
}

export async function runScan(input: ScanInput): Promise<ScanOutcome> {
  const ip = input.ipAddress?.trim() || "unknown";

  const slot = takeScanSlot(ip);
  if (!slot.ok) {
    return { ok: false, error: { code: "rate_limited", resetAt: slot.resetAt } };
  }

  const file = input.photo;
  if (!file || !(file instanceof File) || file.size === 0) {
    return { ok: false, error: { code: "missing_photo" } };
  }
  if (file.size > MAX_PHOTO_BYTES) {
    return { ok: false, error: { code: "photo_too_large" } };
  }
  const mime = file.type || "application/octet-stream";
  if (!SUPPORTED_MIME.has(mime)) {
    return { ok: false, error: { code: "unsupported_image" } };
  }

  const bytes = Buffer.from(await file.arrayBuffer());
  const base64 = bytes.toString("base64");
  const slug = randomUUID().replace(/-/g, "");
  const photoPath = `${slug}/photo.${extFor(mime)}`;

  let item: Item;
  let comps: EbayComp[];
  let guidance: PriceGuidance;
  try {
    item = await identifyItem({
      imageBase64: base64,
      mimeType: mime,
      userContext: input.userContext,
    });
    comps = await fetchSoldComps(item);
    guidance = await suggestPrice({ item, comps });
  } catch (err) {
    console.error("[scan] ai pipeline failed", err);
    return { ok: false, error: { code: "ai_failed" } };
  }

  const supabase = supabaseAdmin();

  const upload = await supabase.storage
    .from("scan-photos")
    .upload(photoPath, bytes, {
      contentType: mime,
      upsert: false,
    });
  if (upload.error) {
    console.error("[scan] photo upload failed", upload.error);
    return { ok: false, error: { code: "server_error" } };
  }
  const { data: publicUrl } = supabase.storage
    .from("scan-photos")
    .getPublicUrl(photoPath);

  const insert = await supabase
    .from("price_scans")
    .insert({
      shareable_slug: slug,
      ip_address: ip,
      item_data: {
        item,
        guidance,
        photo_path: photoPath,
        photo_url: publicUrl.publicUrl,
        user_context: input.userContext?.trim() || null,
        identify_prompt_version: IDENTIFY_ITEM_PROMPT_VERSION,
        guidance_prompt_version: PRICE_GUIDANCE_PROMPT_VERSION,
      },
      comp_data: comps,
    })
    .select("shareable_slug")
    .single();

  if (insert.error) {
    console.error("[scan] insert failed", insert.error);
    return { ok: false, error: { code: "server_error" } };
  }

  return {
    ok: true,
    data: {
      slug,
      item,
      guidance,
      comp_count: comps.length,
      photo_url: publicUrl.publicUrl,
    },
  };
}
