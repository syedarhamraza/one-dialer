import type { Metadata } from "next";
import { readFile } from "node:fs/promises";
import path from "node:path";
import Link from "next/link";
import { marked } from "marked";
import { CaretLeftIcon } from "@phosphor-icons/react/dist/ssr";
import { Footer } from "@/components/Footer";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Toc } from "./Toc";

export const metadata: Metadata = { title: "Privacy policy · One Dialer" };

// En and em dash, normalised to hyphens to match the site's typography.
const DASHES = new RegExp(`\\s?[${String.fromCharCode(0x2013, 0x2014)}]\\s?`, "g");
const slug = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

// Rendered at build time from the repo's docs/privacy-policy.md. The page sets the title and the date itself,
// so those two lines come out of the body; each "## " heading gets an id and a place in the contents.
async function policy() {
  const md = (await readFile(path.join(process.cwd(), "..", "docs", "privacy-policy.md"), "utf8")).replace(DASHES, (m) => (m.trim() === m ? "-" : " - "));
  const updated = /^_Last updated: (.+)_\s*$/m.exec(md)?.[1];
  const sections: { id: string; title: string }[] = [];
  const body = md.replace(/^# .*\r?\n/, "").replace(/^_Last updated: .+_\s*$/m, "");
  const html = (await marked.parse(body)).replace(/<h2>(.*?)<\/h2>/g, (_, title: string) => {
    const id = slug(title);
    sections.push({ id, title });
    return `<h2 id="${id}">${title}</h2>`;
  });
  return { html, updated, sections };
}

export default async function OneDialerPrivacy() {
  const { html, updated, sections } = await policy();
  return (
    <>
      <SmoothScroll />
      {/* The app's pushed-page header: a round glass Back button, and the title once the big one has scrolled under it. */}
      <header className="subpage-bar sticky top-0 z-50 flex h-[72px] items-center gap-4 px-[clamp(16px,4.4vw,64px)]">
        <Link href="/" aria-label="Back to One Dialer" className="glass press grid h-11 w-11 place-items-center rounded-full">
          <CaretLeftIcon size={20} weight="bold" />
        </Link>
        <span aria-hidden className="subpage-title text-[18px] font-semibold tracking-[-0.02em]">
          Privacy policy
        </span>
      </header>

      <main className="mx-auto max-w-[1440px] px-[clamp(16px,4.4vw,64px)] pt-8 pb-28 md:pt-14 md:pb-40">
        <h1 className="text-[clamp(3rem,8vw,6rem)] leading-[0.94] font-bold tracking-[-0.04em]">
          Privacy
          <br />
          <span className="text-ink-2">policy.</span>
        </h1>
        {updated && <p className="mt-7 text-[17px] text-ink-2">Last updated {updated}</p>}

        <div className="mt-14 grid grid-cols-1 gap-x-10 gap-y-12 md:mt-20 lg:grid-cols-12">
          <Toc sections={sections} className="lg:sticky lg:top-28 lg:col-span-4 lg:self-start" />
          <article className="policy lg:col-span-8" dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </main>

      <Footer />
    </>
  );
}
