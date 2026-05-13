import { NextResponse, type NextRequest } from "next/server";
import { joinWaitlist } from "@/lib/waitlist";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ data: null, error: "invalid_json" }, { status: 400 });
  }

  const { email, source } = (body ?? {}) as { email?: unknown; source?: unknown };

  if (typeof email !== "string") {
    return NextResponse.json(
      { data: null, error: "invalid_email" },
      { status: 400 },
    );
  }

  const result = await joinWaitlist({
    email,
    source: typeof source === "string" ? source : null,
    userAgent: req.headers.get("user-agent"),
    ipAddress:
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      req.headers.get("x-real-ip"),
  });

  if (!result.ok) {
    const status = result.error === "invalid_email" ? 400 : 500;
    return NextResponse.json({ data: null, error: result.error }, { status });
  }
  return NextResponse.json({ data: { ok: true }, error: null });
}
