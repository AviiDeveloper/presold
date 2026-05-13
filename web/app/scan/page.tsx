import type { Metadata } from "next";
import Link from "next/link";
import { ScanForm } from "./scan-form";

export const metadata: Metadata = {
  title: "Price scanner — PreSold",
  description:
    "Snap a photo, get the sold price. UK reseller price guidance from real eBay sold comps, in under a minute.",
};

export default function ScanPage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-3xl flex-col px-6 py-10 sm:py-16">
      <header className="flex items-center justify-between">
        <Link href="/" className="text-base font-semibold tracking-tight">
          PreSold
        </Link>
        <span className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
          Free price scanner
        </span>
      </header>

      <section className="mt-12 sm:mt-16">
        <h1 className="text-3xl font-semibold tracking-tight sm:text-5xl">
          What&apos;s it worth?
        </h1>
        <p className="mt-4 max-w-2xl text-base text-(--color-muted-foreground) sm:text-lg">
          Snap one photo. We identify it and pull real sold prices from eBay
          UK to give you a quick, balanced, and patient-seller price.
        </p>
        <p className="mt-2 text-xs text-(--color-muted-foreground)">
          Three scans per day. No signup. Best on a clear, well-lit photo.
        </p>
      </section>

      <section className="mt-10">
        <ScanForm />
      </section>

      <footer className="mt-auto pt-28 text-xs text-(--color-muted-foreground)">
        <div className="flex flex-wrap items-center justify-between gap-4 border-t border-(--color-border) pt-6">
          <span>© {new Date().getFullYear()} PreSold</span>
          <Link href="/" className="underline-offset-4 hover:underline">
            Back to home
          </Link>
        </div>
      </footer>
    </main>
  );
}
