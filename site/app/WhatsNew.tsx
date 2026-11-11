import { readFile } from "node:fs/promises";
import path from "node:path";
import { Reveal } from "./Reveal";

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

export async function WhatsNew() {
  const r = await latest();
  return (
    <section id="whats-new" className="mx-auto grid max-w-[1400px] grid-cols-1 gap-12 px-4 py-28 sm:px-8 md:py-36 lg:grid-cols-12">
      <Reveal className="lg:col-span-4">
        <h2 className="text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em]">
          What&apos;s <span className="text-ink-2">new.</span>
        </h2>
        <p className="mt-6 text-[17px] text-ink-2">
          {label(r.version)} · {r.date}
        </p>
      </Reveal>
      <Reveal className="overflow-hidden rounded-[var(--radius-card)] bg-card lg:col-span-8">
        <ul>
          {r.changes.map((c, i) => (
            <li key={c} className={`flex gap-4 px-6 py-5 text-[16.5px] leading-relaxed text-ink-2 sm:px-8 ${i ? "border-t border-white/[0.06]" : ""}`}>
              <span className="mt-[0.6em] h-1.5 w-1.5 shrink-0 rounded-full bg-green" />
              <span>{c}</span>
            </li>
          ))}
        </ul>
      </Reveal>
    </section>
  );
}
