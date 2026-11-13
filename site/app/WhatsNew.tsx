import { readFile } from "node:fs/promises";
import path from "node:path";

type Release = { version: string; date: string; changes: string[] };

// Read at build time from public/changelog.json, which tool/release.ps1 writes every release, so this
// section updates itself (the app's Software update reads the same file).
async function latest(): Promise<Release> {
  const json = await readFile(path.join(process.cwd(), "public", "changelog.json"), "utf8");
  return JSON.parse(json);
}

/** "1.0.0-beta.6" → "Beta 6", "1.2.0" → "Version 1.2". */
function label(version: string) {
  const beta = /-beta\.(\d+)$/.exec(version);
  return beta ? `Beta ${beta[1]}` : `Version ${version.split(".").slice(0, 2).join(".")}`;
}

export async function WhatsNew({ className, h2 }: { className: string; h2: string }) {
  const r = await latest();
  return (
    <section id="whats-new" className={`${className} grid scroll-mt-10 grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
      <div className="lg:sticky lg:top-28 lg:col-span-5 lg:self-start">
        <h2 data-split className={h2}>
          What&apos;s new.
          <br />
          <span className="text-ink-2">{label(r.version)}.</span>
        </h2>
        <p data-rise className="mt-6 text-[17px] text-ink-2">
          {r.date}
        </p>
      </div>
      <ul className="lg:col-span-7">
        {r.changes.map((c) => (
          <li key={c} data-rise className="border-t border-white/10 py-5 text-[clamp(1.05rem,1.5vw,1.3rem)] leading-snug last:border-b">
            {c}
          </li>
        ))}
      </ul>
    </section>
  );
}
