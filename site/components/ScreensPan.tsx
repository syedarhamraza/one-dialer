"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { PhoneFrame } from "./PhoneFrame";

gsap.registerPlugin(ScrollTrigger);

const SCREENS = [
  { src: "2-upcoming", title: "Upcoming", body: "Everything due in the next week, month or year, split by the card that pays it." },
  { src: "3-trends", title: "Analytics", body: "Your yearly total, what is left of the budget, and what a pause would save." },
  { src: "4-categories", title: "By category", body: "One ring shows where the money goes. Add your own categories next to the built-ins." },
  { src: "5-detail", title: "Every detail", body: "Price, cycle, currency, annual plan price and next renewal. One tap each." },
  { src: "6-reminders", title: "Reminders", body: "Choose the day and the minute, per subscription or as one default for all." },
  { src: "7-currency", title: "Your currency", body: "Pick a main currency. Each subscription keeps the one it actually bills in." },
  { src: "8-backup", title: "Backups you keep", body: "One file holds everything. Restore points catch you before big changes." },
];

/** Vertical scroll pans a track of real screens (pinned on desktop, native snap row on phones). */
type Screen = { src: string; title: string; body: string };

export function ScreensPan({
  screens = SCREENS.map((s) => ({ ...s, src: `/screens/${s.src}.webp` })),
  app = "One Spend",
  heading = (
    <>
      The whole app,
      <br />
      <span className="text-ink-2">one hand.</span>
    </>
  ),
  intro = "Seven screens from the real app. Dark on true black, so an OLED panel simply switches its pixels off.",
}: { screens?: Screen[]; app?: string; heading?: React.ReactNode; intro?: string } = {}) {
  const wrap = useRef<HTMLElement>(null);
  const track = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!wrap.current || !track.current) return;
    const mm = gsap.matchMedia();

    mm.add("(min-width: 768px) and (prefers-reduced-motion: no-preference)", () => {
      const t = track.current!;
      const distance = () => t.scrollWidth - window.innerWidth;
      const pan = gsap.to(t, {
        x: () => -distance(),
        ease: "none",
        scrollTrigger: {
          trigger: wrap.current,
          start: "top top",
          end: () => `+=${distance()}`,
          pin: true,
          scrub: 1,
          invalidateOnRefresh: true,
        },
      });

      // Each phone rises and straightens as it travels into the middle of the screen.
      gsap.utils.toArray<HTMLElement>("[data-phone]", t).forEach((p) => {
        gsap.fromTo(
          p,
          { y: 70, rotate: 4, scale: 0.9 },
          {
            y: 0,
            rotate: 0,
            scale: 1,
            ease: "power2.out",
            scrollTrigger: { trigger: p, containerAnimation: pan, start: "left 95%", end: "center 55%", scrub: true },
          },
        );
      });
    });

    return () => mm.revert();
  }, []);

  return (
    <section id="screens" ref={wrap} className="relative overflow-hidden" aria-label="Screens from the app">
      <div
        ref={track}
        className="no-scrollbar flex items-center gap-[clamp(1.5rem,4vw,4.5rem)] px-4 py-24 max-md:snap-x max-md:snap-mandatory max-md:overflow-x-auto sm:px-8 md:h-[100dvh] md:w-max md:py-0 md:pr-[12vw]"
      >
        <div className="shrink-0 max-md:w-[84vw] md:w-[42vw] md:pl-[4vw]">
          <h2 className="text-[clamp(2.5rem,5.2vw,5rem)] leading-[0.98] font-bold tracking-[-0.05em]">{heading}</h2>
          <p className="mt-6 max-w-[34ch] text-[17px] leading-relaxed text-ink-2">{intro}</p>
        </div>
        {screens.map((s) => (
          <figure key={s.src} className="w-[min(72vw,300px)] shrink-0 max-md:snap-center md:w-[min(300px,calc((100dvh-230px)/2.17))]">
            <div data-phone className="will-change-transform">
              <PhoneFrame src={s.src} alt={`${s.title} screen in ${app}`} />
            </div>
            <figcaption className="mt-6 px-1">
              <p className="text-[18px] font-semibold tracking-[-0.02em]">{s.title}</p>
              <p className="mt-1 text-[15px] leading-snug text-ink-2">{s.body}</p>
            </figcaption>
          </figure>
        ))}
      </div>
    </section>
  );
}
