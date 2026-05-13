import "server-only";
import { supabaseAdmin } from "./supabase";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export type JoinResult =
  | { ok: true }
  | { ok: false; error: "invalid_email" | "server_error" };

export type JoinInput = {
  email: string;
  source?: string | null;
  userAgent?: string | null;
  ipAddress?: string | null;
};

export async function joinWaitlist(input: JoinInput): Promise<JoinResult> {
  const email = input.email?.trim().toLowerCase();
  if (!email || !EMAIL_RE.test(email)) return { ok: false, error: "invalid_email" };

  const { error } = await supabaseAdmin()
    .from("waitlist")
    .insert({
      email,
      source: input.source ? input.source.slice(0, 64) : null,
      user_agent: input.userAgent ?? null,
      ip_address: input.ipAddress ?? null,
    });

  // 23505 = unique_violation — treat as success.
  if (error && error.code !== "23505") {
    console.error("[waitlist] insert failed", error);
    return { ok: false, error: "server_error" };
  }
  return { ok: true };
}
