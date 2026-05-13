import { NextResponse, type NextRequest } from "next/server";
import { runScan, type ScanError } from "@/lib/scan";

export const runtime = "nodejs";

// Full scan = Haiku vision (~5s) + Apify cold-start (up to ~25s) + price
// guidance (~2s) + storage upload + DB insert. Easily blows past Vercel's
// default 10s function timeout on Hobby. Lift to 60s — still well under
// the Hobby plan ceiling.
export const maxDuration = 60;

function status(error: ScanError): number {
  switch (error.code) {
    case "rate_limited":
      return 429;
    case "missing_photo":
    case "photo_too_large":
    case "unsupported_image":
      return 400;
    case "ai_failed":
    case "server_error":
      return 500;
  }
}

export async function POST(req: NextRequest) {
  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return NextResponse.json(
      { data: null, error: { code: "missing_photo" } },
      { status: 400 },
    );
  }

  const photo = form.get("photo");
  const userContextRaw = form.get("category_hint");
  const userContext =
    typeof userContextRaw === "string" ? userContextRaw : null;

  if (!(photo instanceof File)) {
    return NextResponse.json(
      { data: null, error: { code: "missing_photo" } },
      { status: 400 },
    );
  }

  const ipAddress =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    req.headers.get("x-real-ip") ||
    null;

  const result = await runScan({ photo, userContext, ipAddress });

  if (!result.ok) {
    return NextResponse.json(
      { data: null, error: result.error },
      { status: status(result.error) },
    );
  }
  return NextResponse.json({ data: result.data, error: null });
}
