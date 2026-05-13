"use client";

import { useRef, useState } from "react";
import type { Item, PriceGuidance } from "@/lib/types";

type ScanResult = {
  slug: string;
  item: Item;
  guidance: PriceGuidance;
  comp_count: number;
  photo_url: string;
};

type ScanError = {
  code:
    | "rate_limited"
    | "missing_photo"
    | "photo_too_large"
    | "unsupported_image"
    | "ai_failed"
    | "server_error";
  resetAt?: number;
};

type ApiResponse =
  | { data: ScanResult; error: null }
  | { data: null; error: ScanError };

type Status =
  | { kind: "idle" }
  | { kind: "submitting" }
  | { kind: "ok"; result: ScanResult }
  | { kind: "error"; message: string };

function errorMessage(error: ScanError): string {
  switch (error.code) {
    case "rate_limited": {
      const reset = error.resetAt
        ? new Date(error.resetAt).toLocaleTimeString("en-GB", {
            hour: "2-digit",
            minute: "2-digit",
          })
        : "tomorrow";
      return `Three scans a day, on the house. Come back at ${reset}.`;
    }
    case "missing_photo":
      return "Pick a photo first.";
    case "photo_too_large":
      return "Photo's too big. 10MB max — try a smaller one.";
    case "unsupported_image":
      return "JPEG, PNG, WebP or GIF only.";
    case "ai_failed":
      return "The AI choked on that one. Try a clearer photo.";
    case "server_error":
      return "Something broke on our side. Try again in a minute.";
  }
}

function formatGbp(n: number) {
  return new Intl.NumberFormat("en-GB", {
    style: "currency",
    currency: "GBP",
    maximumFractionDigits: n >= 100 ? 0 : 2,
  }).format(n);
}

export function ScanForm() {
  const [status, setStatus] = useState<Status>({ kind: "idle" });
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const formRef = useRef<HTMLFormElement | null>(null);

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) {
      setPreviewUrl(null);
      return;
    }
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(URL.createObjectURL(file));
  }

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus({ kind: "submitting" });

    const data = new FormData(e.currentTarget);
    try {
      const res = await fetch("/api/scan", { method: "POST", body: data });
      const body = (await res.json()) as ApiResponse;
      if (body.error) {
        setStatus({ kind: "error", message: errorMessage(body.error) });
        return;
      }
      setStatus({ kind: "ok", result: body.data });
    } catch {
      setStatus({
        kind: "error",
        message: "Couldn't reach the server. Check your connection.",
      });
    }
  }

  function onReset() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(null);
    setStatus({ kind: "idle" });
    formRef.current?.reset();
  }

  if (status.kind === "ok") {
    return <ScanResultView result={status.result} onReset={onReset} />;
  }

  return (
    <form
      ref={formRef}
      onSubmit={onSubmit}
      className="flex flex-col gap-5"
      encType="multipart/form-data"
    >
      <label className="flex flex-col gap-2">
        <span className="text-sm font-medium">Photo</span>
        <input
          type="file"
          name="photo"
          accept="image/jpeg,image/png,image/webp,image/gif"
          capture="environment"
          required
          onChange={onFileChange}
          className="block w-full rounded-md border border-(--color-border) bg-background p-3 text-sm file:mr-3 file:rounded file:border-0 file:bg-foreground file:px-3 file:py-1.5 file:text-background"
        />
        <span className="text-xs text-(--color-muted-foreground)">
          One clear photo. Front of the item, good light, neutral background.
        </span>
      </label>

      {previewUrl && (
        <div className="overflow-hidden rounded-md border border-(--color-border)">
          {/* Preview only, local blob URL */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={previewUrl}
            alt="Photo preview"
            className="block max-h-80 w-full object-contain"
          />
        </div>
      )}

      <label className="flex flex-col gap-2">
        <span className="text-sm font-medium">
          Category hint{" "}
          <span className="font-normal text-(--color-muted-foreground)">
            (optional)
          </span>
        </span>
        <input
          type="text"
          name="category_hint"
          maxLength={120}
          placeholder="e.g. men's trainers, vintage band tee"
          className="rounded-md border border-(--color-border) bg-background px-4 py-3 text-sm placeholder:text-(--color-muted-foreground) focus:border-foreground focus:outline-none"
        />
      </label>

      <button
        type="submit"
        disabled={status.kind === "submitting"}
        className="self-start rounded-md bg-foreground px-5 py-3 text-sm font-medium text-background transition hover:opacity-90 disabled:opacity-50"
      >
        {status.kind === "submitting" ? "Scanning..." : "Scan it"}
      </button>

      {status.kind === "error" && (
        <p className="text-sm text-red-600" role="alert">
          {status.message}
        </p>
      )}
    </form>
  );
}

function ScanResultView({
  result,
  onReset,
}: {
  result: ScanResult;
  onReset: () => void;
}) {
  const { item, guidance, comp_count, photo_url } = result;
  return (
    <div className="flex flex-col gap-8">
      <div className="grid gap-6 sm:grid-cols-2">
        <div className="overflow-hidden rounded-md border border-(--color-border)">
          {/* Public Supabase storage URL */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={photo_url}
            alt={item.title}
            className="block max-h-80 w-full object-contain"
          />
        </div>
        <div className="flex flex-col gap-2">
          <h2 className="text-xl font-semibold tracking-tight">{item.title}</h2>
          <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-sm">
            {item.brand && (
              <>
                <dt className="text-(--color-muted-foreground)">Brand</dt>
                <dd>{item.brand}</dd>
              </>
            )}
            <dt className="text-(--color-muted-foreground)">Category</dt>
            <dd>{item.category}</dd>
            {item.size && (
              <>
                <dt className="text-(--color-muted-foreground)">Size</dt>
                <dd>{item.size}</dd>
              </>
            )}
            <dt className="text-(--color-muted-foreground)">Colour</dt>
            <dd>{item.color}</dd>
            <dt className="text-(--color-muted-foreground)">Condition</dt>
            <dd>{item.condition.replace(/_/g, " ")}</dd>
          </dl>
          <p className="mt-2 text-xs text-(--color-muted-foreground)">
            AI confidence: {Math.round(item.confidence * 100)}%
          </p>
        </div>
      </div>

      <div className="rounded-md border border-(--color-border) p-6">
        <p className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
          Price guidance · {comp_count} sold comp
          {comp_count === 1 ? "" : "s"}
        </p>
        <div className="mt-4 grid gap-4 sm:grid-cols-3">
          <PriceTile
            label="Quick sale"
            price={guidance.price_low}
            tone="muted"
          />
          <PriceTile
            label="Recommended"
            price={guidance.price_recommended}
            tone="accent"
          />
          <PriceTile
            label="Patient seller"
            price={guidance.price_high}
            tone="muted"
          />
        </div>
        <p className="mt-5 text-sm">{guidance.reasoning}</p>
        <p className="mt-2 text-xs text-(--color-muted-foreground)">
          Estimated sell speed: {guidance.sell_speed_estimate} · AI confidence:{" "}
          {Math.round(guidance.confidence * 100)}%
        </p>
      </div>

      <button
        type="button"
        onClick={onReset}
        className="self-start rounded-md border border-(--color-border) px-5 py-3 text-sm font-medium transition hover:bg-(--color-muted)"
      >
        Scan another
      </button>
    </div>
  );
}

function PriceTile({
  label,
  price,
  tone,
}: {
  label: string;
  price: number;
  tone: "muted" | "accent";
}) {
  return (
    <div
      className={
        tone === "accent"
          ? "rounded-md bg-(--color-accent) p-4 text-(--color-accent-foreground)"
          : "rounded-md bg-(--color-muted) p-4"
      }
    >
      <p className="text-xs uppercase tracking-widest opacity-80">{label}</p>
      <p className="mt-1 text-2xl font-semibold tracking-tight">
        {formatGbp(price)}
      </p>
    </div>
  );
}
