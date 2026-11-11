import type { Metadata } from "next";
import { readFile } from "node:fs/promises";
import path from "node:path";
import Link from "next/link";
import { marked } from "marked";
import { CaretLeftIcon } from "@phosphor-icons/react/dist/ssr";

export const metadata: Metadata = { title: "Privacy policy · One Dialer" };

// En and em dash, normalised to hyphens to match the site's typography.
const DASHES = new RegExp(`\\s?[${String.fromCharCode(0x2013, 0x2014)}]\\s?`, "g");

// Rendered at build time from the repo's docs/privacy-policy.md.
async function policyHtml() {
  const md = await readFile(path.join(process.cwd(), "..", "docs", "privacy-policy.md"), "utf8");
  return marked.parse(md.replace(DASHES, (m) => (m.trim() === m ? "-" : " - ")));
}

export default async function OneDialerPrivacy() {
  const html = await policyHtml();
  return (
    <main className="mx-auto max-w-[720px] px-4 pt-6 pb-32 sm:px-8">
      {/* OneUISubpage header: back button and small title. */}
      <Link
        href="/"
        className="glass inline-flex h-11 items-center gap-1 rounded-[var(--radius-pill)] pr-4 pl-3 text-[15px] font-semibold"
      >
        <CaretLeftIcon size={18} weight="bold" /> One Dialer
      </Link>
      <article
        className="mt-10 text-[16.5px] leading-relaxed text-ink-2 [&_a]:text-accent [&_a]:underline-offset-4 hover:[&_a]:underline [&_em]:text-ink-3 [&_h1]:mb-6 [&_h1]:text-[clamp(2.4rem,6vw,3.6rem)] [&_h1]:leading-none [&_h1]:font-bold [&_h1]:tracking-[-0.05em] [&_h1]:text-ink [&_h2]:mt-12 [&_h2]:mb-3 [&_h2]:text-[22px] [&_h2]:font-bold [&_h2]:tracking-[-0.02em] [&_h2]:text-ink [&_li]:mt-1.5 [&_p]:mt-4 [&_strong]:text-ink [&_ul]:mt-3 [&_ul]:list-disc [&_ul]:pl-5 [&_ul_ul]:mt-1"
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </main>
  );
}
