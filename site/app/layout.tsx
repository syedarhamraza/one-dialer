import type { Metadata, Viewport } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import { Providers } from "@/components/Providers";
import "./globals.css";

export const metadata: Metadata = {
  // Set NEXT_PUBLIC_SITE_URL at build time once the site has a domain, so OG images resolve.
  metadataBase: process.env.NEXT_PUBLIC_SITE_URL ? new URL(process.env.NEXT_PUBLIC_SITE_URL) : undefined,
  title: "One Dialer",
  description:
    "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
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

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
