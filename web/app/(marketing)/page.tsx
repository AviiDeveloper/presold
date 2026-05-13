import type { Metadata } from "next";
import { WaitlistForm } from "./waitlist-form";

export const metadata: Metadata = {
  title: "PreSold — Lists faster, sells smarter",
  description:
    "UK reseller toolkit. Snap an item, get a Vinted, Depop, and eBay listing in 30 seconds with real sold-comp pricing.",
};

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-6 py-10 sm:py-16">
      <header className="flex items-center justify-between">
        <span className="text-base font-semibold tracking-tight">PreSold</span>
        <span className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
          UK · Coming soon
        </span>
      </header>

      <section className="mt-20 sm:mt-28">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-6xl">
          Lists faster, sells smarter.
        </h1>
        <p className="mt-6 max-w-2xl text-lg text-(--color-muted-foreground) sm:text-xl">
          The reseller toolkit for Vinted, Depop, and eBay UK. Snap an item,
          get a platform-ready listing and a real sold-price in under thirty
          seconds.
        </p>

        <div className="mt-10 max-w-lg">
          <WaitlistForm />
          <p className="mt-3 text-xs text-(--color-muted-foreground)">
            iOS only at launch. £7.99/month after a 14-day trial. No card up front.
          </p>
        </div>
      </section>

      <section className="mt-28 grid gap-10 sm:grid-cols-3">
        <div>
          <p className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
            01 · Capture
          </p>
          <h2 className="mt-2 text-lg font-semibold">Snap the item</h2>
          <p className="mt-2 text-sm text-(--color-muted-foreground)">
            Up to six photos. Front, back, tag, flaws. The app handles the rest.
          </p>
        </div>
        <div>
          <p className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
            02 · Generate
          </p>
          <h2 className="mt-2 text-lg font-semibold">Listing + price</h2>
          <p className="mt-2 text-sm text-(--color-muted-foreground)">
            AI writes the title, description and tags for each platform. Sold
            comps from eBay set the price.
          </p>
        </div>
        <div>
          <p className="text-xs uppercase tracking-widest text-(--color-muted-foreground)">
            03 · Post
          </p>
          <h2 className="mt-2 text-lg font-semibold">Copy and paste</h2>
          <p className="mt-2 text-sm text-(--color-muted-foreground)">
            One tap per platform. Paste into Vinted, Depop, eBay. Profit tracked
            when the sale email lands.
          </p>
        </div>
      </section>

      <section className="mt-28 border-t border-(--color-border) pt-12">
        <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
          The bit that hurts
        </h2>
        <p className="mt-4 max-w-2xl text-base text-(--color-muted-foreground) sm:text-lg">
          A serious reseller writes ten to thirty listings a week. Each one is
          five to fifteen minutes of titles, descriptions, tags, and second-
          guessing the price. That&apos;s a working day, every week, on admin.
        </p>
        <p className="mt-4 max-w-2xl text-base text-(--color-muted-foreground) sm:text-lg">
          The US-built tools cost £30 a month and treat UK platforms as an
          afterthought. PreSold is built for UK resellers, by one.
        </p>
      </section>

      <footer className="mt-auto pt-28 text-xs text-(--color-muted-foreground)">
        <div className="flex flex-wrap items-center justify-between gap-4 border-t border-(--color-border) pt-6">
          <span>© {new Date().getFullYear()} PreSold</span>
          <span>Made in the UK</span>
        </div>
      </footer>
    </main>
  );
}
