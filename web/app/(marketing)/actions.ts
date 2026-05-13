"use server";

import { headers } from "next/headers";
import { joinWaitlist } from "@/lib/waitlist";

export type WaitlistFormState =
  | { status: "idle" }
  | { status: "ok" }
  | { status: "error"; message: string };

export async function submitWaitlist(
  _prev: WaitlistFormState,
  formData: FormData,
): Promise<WaitlistFormState> {
  const email = String(formData.get("email") ?? "");
  const source = String(formData.get("source") ?? "landing");

  const h = await headers();
  const userAgent = h.get("user-agent");
  const ipAddress =
    h.get("x-forwarded-for")?.split(",")[0]?.trim() || h.get("x-real-ip");

  const result = await joinWaitlist({ email, source, userAgent, ipAddress });

  if (!result.ok) {
    return {
      status: "error",
      message:
        result.error === "invalid_email"
          ? "That doesn't look like a valid email."
          : "Something broke on our side. Try again in a minute.",
    };
  }
  return { status: "ok" };
}
