import "server-only";

/**
 * In-memory IP rate limiter for the free price scanner.
 * PLAN §8: "rate-limit free scanner to 3 scans per IP per day".
 *
 * In-memory is fine for v1 — Vercel serverless instances may reset the map on
 * cold starts, which conservatively under-counts (i.e. lets a few extra scans
 * through after a redeploy). Acceptable for a content-magnet scanner; revisit
 * with Upstash or Vercel KV if abuse becomes real.
 */

const WINDOW_MS = 24 * 60 * 60 * 1000;
const MAX_PER_WINDOW = 3;

const hits = new Map<string, number[]>();

function pruneAndCount(ip: string, now: number) {
  const cutoff = now - WINDOW_MS;
  const fresh = (hits.get(ip) ?? []).filter((t) => t > cutoff);
  hits.set(ip, fresh);
  return fresh;
}

export type RateLimitResult =
  | { ok: true; remaining: number; resetAt: number }
  | { ok: false; resetAt: number };

/** Atomically check + record a scan from this IP. */
export function takeScanSlot(ip: string): RateLimitResult {
  const now = Date.now();
  const fresh = pruneAndCount(ip, now);
  if (fresh.length >= MAX_PER_WINDOW) {
    const resetAt = (fresh[0] ?? now) + WINDOW_MS;
    return { ok: false, resetAt };
  }
  fresh.push(now);
  hits.set(ip, fresh);
  return {
    ok: true,
    remaining: MAX_PER_WINDOW - fresh.length,
    resetAt: now + WINDOW_MS,
  };
}
