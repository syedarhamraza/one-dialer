import type { Metadata, Viewport } from "next";
import { GeistSans } from "geist/font/sans";
import "./globals.css";

export const metadata: Metadata = {
  // Set NEXT_PUBLIC_SITE_URL at build time once the site has a domain, so OG images resolve.
  metadataBase: process.env.NEXT_PUBLIC_SITE_URL ? new URL(process.env.NEXT_PUBLIC_SITE_URL) : undefined,
  title: "One Dialer",
  description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
  icons: { icon: "/one-dialer/icon.png", apple: "/one-dialer/icon.png" },
  openGraph: {
    title: "One Dialer",
    description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
    images: ["/one-dialer/og.png"],
  },
};

export const viewport: Viewport = {
  themeColor: "#000000",
  colorScheme: "dark",
};

// Before first paint: mark that scripts run (so entrances may start hidden), and start people who ask their
// system for less transparency at Off effects.
const BOOT = `document.documentElement.classList.add("js");if(matchMedia("(prefers-reduced-transparency: reduce)").matches)document.documentElement.dataset.fx="off"`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // data-fx is the page's Reduce visual effects level (lib/fx.ts); the script above may change both attributes.
    <html lang="en" data-fx="full" className={GeistSans.variable} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: BOOT }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
