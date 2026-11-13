"use client";

import { useEffect } from "react";
import Lenis from "lenis";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

let lenis: Lenis | null = null;

/** Glides to a place on the page (an element or a scroll position); jumps there for reduced motion. */
export function scrollTo(target: HTMLElement | number) {
  if (lenis) lenis.scrollTo(target, { duration: 1.4, easing: (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2) });
  else if (typeof target === "number") window.scrollTo(0, target);
  else target.scrollIntoView();
}

/** Lenis smooth scroll, driven by GSAP's ticker so ScrollTrigger pins stay in sync. Off for reduced motion. */
export function SmoothScroll() {
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const l = (lenis = new Lenis({ lerp: 0.11, wheelMultiplier: 0.95 }));
    l.on("scroll", ScrollTrigger.update);
    const tick = (time: number) => l.raf(time * 1000);
    gsap.ticker.add(tick);
    gsap.ticker.lagSmoothing(0);

    // In-page anchors glide instead of jumping.
    const onClick = (e: MouseEvent) => {
      const a = (e.target as HTMLElement).closest<HTMLAnchorElement>('a[href^="#"]');
      const target = a && document.querySelector<HTMLElement>(a.getAttribute("href")!);
      if (!target) return;
      e.preventDefault();
      scrollTo(target);
    };
    document.addEventListener("click", onClick);

    return () => {
      document.removeEventListener("click", onClick);
      gsap.ticker.remove(tick);
      l.destroy();
      lenis = null;
    };
  }, []);

  return null;
}
