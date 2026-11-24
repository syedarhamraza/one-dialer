"use client";

import { useState } from "react";
import { BackspaceIcon, PhoneIcon } from "@phosphor-icons/react";
import { PLAY_URL, RELEASED } from "@/app/links";
import { type Fx, setFx, useFx } from "@/lib/fx";
import { CYRILLIC, t9Match } from "@/lib/t9";

// The made-up people from the app's store screenshots (Ofcom and NANP numbers reserved for fiction).
const PEOPLE = [
  { name: "Emma Clarke", number: "07700 900461", tint: "#f17ab4" },
  { name: "Priya Shah", number: "07700 900750", tint: "#8f8ef5" },
  { name: "Daniel Reyes", number: "202 555 0143", tint: "#7f9af5" },
  { name: "Sofia Bianchi", number: "312 345 6780", tint: "#c48af2" },
  { name: "Marco Rossi", number: "312 345 6782", tint: "#4fcf9a" },
];

const KEYS = [
  ["1", ""],
  ["2", "ABC"],
  ["3", "DEF"],
  ["4", "GHI"],
  ["5", "JKL"],
  ["6", "MNO"],
  ["7", "PQRS"],
  ["8", "TUV"],
  ["9", "WXYZ"],
  ["*", ""],
  ["0", "+"],
  ["#", ""],
];

const LEVELS: Fx[] = ["full", "reduced", "off"];

type Level = { label: string; text: string };
type KeypadText = { hint: string; none: string; delete: string; joinBeta: string; play: string };

/** The app's keypad, working: the keys type, and T9 finds people by the letters on them. */
export function Keypad({ t, cyrillic = false }: { t: KeypadText; cyrillic?: boolean }) {
  const [digits, setDigits] = useState("");
  const found = PEOPLE.map((p) => ({ ...p, hit: t9Match(p.name, digits) })).filter(
    (p) => !digits || p.hit || p.number.replace(/\s/g, "").includes(digits),
  );

  return (
    <div className="mx-auto w-full max-w-[400px]">
      <p aria-live="polite" className="tabular flex h-16 items-center justify-center text-[34px] font-medium tracking-[-0.02em]">
        {digits || <span className="text-[17px] font-normal tracking-normal text-ink-3">{t.hint}</span>}
      </p>
      <ul className="h-[272px] overflow-hidden">
        {found.slice(0, 4).map((p) => (
          <li key={p.name} className="flex h-[68px] items-center gap-4 border-b border-white/10 px-2">
            <span aria-hidden className="grid h-11 w-11 shrink-0 place-items-center rounded-full text-[15px] font-medium" style={{ background: p.tint }}>
              {p.name
                .split(" ")
                .map((w) => w[0])
                .join("")}
            </span>
            <span className="min-w-0 flex-1 truncate text-[18px]">
              {p.hit ? (
                <>
                  {p.name.slice(0, p.hit[0])}
                  <span className="text-accent">{p.name.slice(...p.hit)}</span>
                  {p.name.slice(p.hit[1])}
                </>
              ) : (
                p.name
              )}
            </span>
            <span className="tabular text-[15px] text-ink-2">{p.number}</span>
          </li>
        ))}
        {!found.length && <li className="grid h-[68px] place-items-center text-[16px] text-ink-2">{t.none}</li>}
      </ul>
      {/* The sheet rides up over the list, as it does over Calls in the app, so its frost has something to blur. */}
      <div className="glass relative -mt-24 rounded-[var(--radius-pill)] p-3.5">
        <div className="grid grid-cols-3 gap-2.5">
          {KEYS.map(([d, latin]) => {
            // Russian keys carry the Cyrillic letters too, as in the app (and AOSP's dialer).
            const letters = cyrillic && CYRILLIC[d] ? `${latin} ${CYRILLIC[d]}` : latin;
            return (
              <button key={d} type="button" onClick={() => setDigits((v) => (v + d).slice(0, 12))} className="key press" aria-label={letters ? `${d}, ${letters}` : d}>
                <span className="text-[26px] leading-none font-medium">{d}</span>
                <span className={`mt-1 h-3 leading-none whitespace-nowrap text-ink-2 ${cyrillic ? "text-[9.5px] tracking-[0.04em]" : "text-[10.5px] tracking-[0.12em]"}`}>{letters}</span>
              </button>
            );
          })}
          <span />
          {/* The Call key places the only call this page can: to the app itself. */}
          <a
            {...(RELEASED ? { href: PLAY_URL, target: "_blank", rel: "noopener noreferrer", "aria-label": t.play } : { href: "#join", "aria-label": t.joinBeta })}
            className="key lit press"
          >
            <PhoneIcon size={26} weight="fill" />
          </a>
          <button type="button" onClick={() => setDigits((v) => v.slice(0, -1))} className="key press" aria-label={t.delete} disabled={!digits}>
            <BackspaceIcon size={26} weight="fill" className={digits ? "" : "opacity-30"} />
          </button>
        </div>
      </div>
    </div>
  );
}

/** Settings › Reduce visual effects, wired to this page's own glass. */
export function EffectsPicker({ t }: { t: { label: string } & Record<Fx, Level> }) {
  const fx = useFx();
  const i = LEVELS.indexOf(fx);
  return (
    <div>
      <div role="group" aria-label={t.label} className="glass relative inline-grid grid-cols-3 rounded-full p-1.5">
        <span aria-hidden className="seg-thumb absolute inset-y-1.5 left-1.5 w-[calc((100%-12px)/3)] rounded-full bg-pill-active" style={{ "--i": i } as React.CSSProperties} />
        {LEVELS.map((l) => (
          <button
            key={l}
            type="button"
            aria-pressed={l === fx}
            onClick={() => setFx(l)}
            className="relative h-11 px-6 text-[16px] font-semibold text-ink-2 transition-colors duration-300 aria-pressed:text-ink max-sm:px-5"
          >
            {t[l].label}
          </button>
        ))}
      </div>
      <p className="mt-5 min-h-[3.2em] max-w-[36ch] text-[17px] leading-relaxed text-ink-2">{t[fx].text}</p>
    </div>
  );
}
