"use client";

import { useEffect } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { SplitText } from "gsap/SplitText";

gsap.registerPlugin(ScrollTrigger, SplitText);

/**
 * The page's motion below the stage, set up once from data attributes so server-rendered sections stay plain HTML:
 * data-split (a heading's lines rise out of a mask), data-rise (rows rise in, staggered), data-pop (a panel springs
 * up to size), data-wordmark (letters stand up as the page ends), data-magnetic (leans toward the pointer).
 * Rendered last on the page, so its scroll positions are measured after the stage's pin.
 */
export function Motion() {
  useEffect(() => {
    // PressGlow lights up where the finger landed.
    const down = (e: PointerEvent) => {
      const el = (e.target as HTMLElement).closest<HTMLElement>(".press");
      if (!el) return;
      const r = el.getBoundingClientRect();
      el.style.setProperty("--px", `${e.clientX - r.left}px`);
      el.style.setProperty("--py", `${e.clientY - r.top}px`);
    };
    document.addEventListener("pointerdown", down);

    const lists = gsap.utils.toArray<HTMLElement>(".glow-list");
    const over = (e: PointerEvent) => {
      const el = e.currentTarget as HTMLElement;
      const r = el.getBoundingClientRect();
      el.style.setProperty("--gx", `${e.clientX - r.left + 24}px`);
      el.style.setProperty("--gy", `${e.clientY - r.top}px`);
    };
    lists.forEach((l) => l.addEventListener("pointermove", over));

    // The header steps aside while reading down and returns on the way up.
    const header = document.querySelector(".site-header");
    const watch = ScrollTrigger.create({ onUpdate: (self) => header?.classList.toggle("is-hidden", self.direction > 0 && self.scroll() > 120) });

    const mm = gsap.matchMedia();
    mm.add("(prefers-reduced-motion: no-preference)", () => {
      gsap.utils.toArray<HTMLElement>("[data-split]").forEach((el) => {
        SplitText.create(el, {
          type: "lines",
          mask: "lines",
          autoSplit: true,
          onSplit: (self) =>
            gsap.from(self.lines, { yPercent: 108, duration: 1.2, ease: "expo.out", stagger: 0.1, scrollTrigger: { trigger: el, start: "top 88%", once: true } }),
        });
      });

      gsap.set("[data-rise]", { y: 40, opacity: 0 });
      ScrollTrigger.batch("[data-rise]", {
        start: "top 92%",
        once: true,
        onEnter: (els) => gsap.to(els, { y: 0, opacity: 1, duration: 1, ease: "expo.out", stagger: 0.07 }),
      });

      gsap.set("[data-pop]", { scale: 0.9, opacity: 0, transformOrigin: "50% 100%" });
      ScrollTrigger.batch("[data-pop]", {
        start: "top 88%",
        once: true,
        onEnter: (els) => gsap.to(els, { scale: 1, opacity: 1, duration: 1.1, ease: "elastic.out(1, 0.75)", stagger: 0.12 }),
      });

      gsap.utils.toArray<HTMLElement>("[data-wordmark]").forEach((el) => {
        const split = SplitText.create(el, { type: "chars" });
        gsap.from(split.chars, { yPercent: 70, opacity: 0, stagger: 0.05, ease: "power2.out", scrollTrigger: { trigger: el, start: "top 100%", end: "bottom 100%", scrub: 0.6 } });
      });

      const magnets = window.matchMedia("(pointer: fine)").matches ? gsap.utils.toArray<HTMLElement>("[data-magnetic]") : [];
      const undo = magnets.map((el) => {
        const x = gsap.quickTo(el, "x", { duration: 0.7, ease: "power3" });
        const y = gsap.quickTo(el, "y", { duration: 0.7, ease: "power3" });
        const lean = (e: PointerEvent) => {
          const r = el.getBoundingClientRect();
          x((e.clientX - r.left - r.width / 2) * 0.3);
          y((e.clientY - r.top - r.height / 2) * 0.3);
        };
        const rest = () => {
          x(0);
          y(0);
        };
        el.addEventListener("pointermove", lean);
        el.addEventListener("pointerleave", rest);
        return () => {
          el.removeEventListener("pointermove", lean);
          el.removeEventListener("pointerleave", rest);
        };
      });
      return () => undo.forEach((u) => u());
    });

    return () => {
      mm.revert();
      watch.kill();
      document.removeEventListener("pointerdown", down);
      lists.forEach((l) => l.removeEventListener("pointermove", over));
    };
  }, []);

  return null;
}
