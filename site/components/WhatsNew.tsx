import { readFile } from "node:fs/promises";
import path from "node:path";
import { DICTS, type Lang, fill } from "@/i18n";

type Release = { version: string; date: string; changes: string[] };

// Read at build time from public/changelog.json, which tool/release.ps1 writes every release, so this
// section updates itself (the app's Software update reads the same file).
async function latest(): Promise<Release> {
  const json = await readFile(path.join(process.cwd(), "public", "changelog.json"), "utf8");
  return JSON.parse(json);
}

/** "1.0.0-beta.6" → "Beta 6", "1.2.0" → "Version 1.2". */
function label(version: string, t: { beta: string; version: string }) {
  const beta = /-beta\.(\d+)$/.exec(version);
  return beta ? fill(t.beta, { n: beta[1] }) : fill(t.version, { v: version.split(".").slice(0, 2).join(".") });
}

/** The changelog's "Nov 2026" in the page's language; anything else as it is. */
function date(s: string, lang: Lang) {
  const d = new Date(`1 ${s}`);
  return lang === "en" || isNaN(+d) ? s : new Intl.DateTimeFormat(lang, { month: "long", year: "numeric" }).format(d);
}

export async function WhatsNew({ className, h2, lang }: { className: string; h2: string; lang: Lang }) {
  const r = await latest();
  const t = DICTS[lang].whatsNew;
  return (
    <section id="whats-new" className={`${className} grid scroll-mt-10 grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
      <div className="lg:sticky lg:top-28 lg:col-span-5 lg:self-start">
        <h2 data-split className={h2}>
          {t.h}
          <br />
          <span className="text-ink-2">{label(r.version, t)}.</span>
        </h2>
        <p data-rise className="mt-6 text-[17px] text-ink-2">
          {date(r.date, lang)}
        </p>
      </div>
      <div className="lg:col-span-7">
        {/* Release notes are written in English only. */}
        <ul lang="en">
          {r.changes.map((c) => (
            <li key={c} data-rise className="border-t border-white/10 py-5 text-[clamp(1.05rem,1.5vw,1.3rem)] leading-snug last:border-b">
              {c}
            </li>
          ))}
        </ul>
        {t.note && <p className="mt-6 text-[15px] text-ink-3">{t.note}</p>}
      </div>
    </section>
  );
}
