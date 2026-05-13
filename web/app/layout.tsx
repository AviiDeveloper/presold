import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "PreSold — Lists faster, sells smarter",
  description:
    "UK-first reseller toolkit. Snap an item, get an AI listing for Vinted, Depop, and eBay with real sold-comp pricing.",
  metadataBase: new URL("https://presold.app"),
  openGraph: {
    title: "PreSold — Lists faster, sells smarter",
    description:
      "Snap, list, sell. AI-written listings and real eBay sold prices for UK resellers.",
    url: "https://presold.app",
    siteName: "PreSold",
    locale: "en_GB",
    type: "website",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#ffffff",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en-GB" className={inter.variable}>
      <body>{children}</body>
    </html>
  );
}
