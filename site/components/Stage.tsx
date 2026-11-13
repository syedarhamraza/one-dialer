"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { ArrowRightIcon } from "@phosphor-icons/react";
import { RELEASED } from "@/app/links";
import { setFx, useFx } from "@/lib/fx";
import { PlayButton } from "./PlayButton";
import { scrollTo } from "./SmoothScroll";
import type { createSlabScene } from "./slabScene";

gsap.registerPlugin(ScrollTrigger);
// A phone's address bar sliding away resizes the window; re-measuring the pin then would make the page jump.
ScrollTrigger.config({ ignoreMobileResize: true });

export type Screen = { src: string; title: string; body: string };

// The aurora behind each step, like the call screen's caller tint: [large glow, small glow].
const TINTS: [string, string][] = [
  ["#6e3cd2", "#00c05a"],
  ["#40404e", "#00c05a"],
  ["#7a4fd6", "#1f8f6a"],
  ["#4a6fd9", "#7a4fd6"],
  ["#b0186e", "#b0402a"],
  ["#8a1560", "#9a3a26"],
];

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
/** Scroll progress to the step the slab shows: it rests on each face, then turns to the next. */
const turn = (p: number) => {
  const i = Math.floor(p);
  const t = clamp01((p - i - 0.16) / 0.68);
  return i + t * t * (3 - 2 * t);
};

/**
 * The first screen and the five after it, pinned: a slab of glass over giant words, turning half a turn per scroll
 * step to the next real screen. The layout is all CSS (.stage in globals.css); at Full effects a WebGL scene
 * (slabScene.ts) draws the words and the slab from those same boxes, with real refraction. Below Full, without
 * WebGL, or for reduced motion, the DOM words and a CSS slab show instead.
 */
export function Stage({ screens }: { screens: Screen[] }) {
  const wrap = useRef<HTMLElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const live = useRef({ p: 0, nx: 0, ny: 0, intro: 0, scene: null as ReturnType<typeof createSlabScene> | null, st: null as ScrollTrigger | null });
  const fx = useFx();
  const N = screens.length;

  // Scroll, pointer and the per-frame update. Runs once; the WebGL scene comes and goes underneath it.
  useEffect(() => {
    const el = wrap.current!;
    const s = live.current;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    const all = <T extends HTMLElement>(q: string) => [...el.querySelectorAll<T>(q)];
    const words = all("[data-word]");
    const caps = all("[data-cap]");
    const dots = all("[data-dot]");
    const faces = all("[data-face]");
    const slab = el.querySelector<HTMLElement>("[data-slab]")!;
    const inner = slab.firstElementChild as HTMLElement;

    const ctx = gsap.context(() => {
      s.st = ScrollTrigger.create({
        trigger: el,
        start: "top top",
        end: () => `+=${window.innerHeight * 0.85 * N}`,
        pin: true,
        anticipatePin: 1,
        scrub: reduce.matches ? true : 0.5,
        invalidateOnRefresh: true,
        animation: gsap.to(s, { p: N, ease: "none" }),
      });
    }, el);

    const nx = gsap.quickTo(s, "nx", { duration: 0.9, ease: "power3" });
    const ny = gsap.quickTo(s, "ny", { duration: 0.9, ease: "power3" });
    const move = (e: PointerEvent) => {
      if (e.pointerType !== "mouse" || reduce.matches) return;
      const r = el.getBoundingClientRect();
      nx((e.clientX - r.left) / r.width - 0.5);
      ny((e.clientY - r.top) / r.height - 0.5);
    };
    el.addEventListener("pointermove", move);

    let visible = true;
    const io = new IntersectionObserver(([e]) => (visible = e.isIntersecting));
    io.observe(el);

    let drawn = "";
    const tick = (time: number) => {
      if (!visible) return;
      const q = reduce.matches ? Math.round(s.p) : turn(s.p);
      const key = [q, s.nx, s.ny, s.intro].map((v) => v.toFixed(4)).join() + !!s.scene;
      if (key !== drawn) {
        drawn = key;
        const step = Math.round(q);
        caps.forEach((c, k) => {
          const d = k - q;
          c.style.opacity = `${clamp01(1 - Math.abs(d) * 2.4)}`;
          c.style.transform = `translateY(${d * 28}px)`;
        });
        dots.forEach((d, k) => (k + 1 === step ? d.setAttribute("aria-current", "true") : d.removeAttribute("aria-current")));
        if (!s.scene) {
          words.forEach((w, k) => {
            const d = k - q;
            w.style.opacity = `${clamp01(1 - Math.abs(d) * 2) * (k ? 1 : s.intro)}`;
            w.style.transform = `translateY(${d * 0.9}em)`;
          });
          const ry = reduce.matches ? 0 : 19.5 + q * 180 + s.nx * 15;
          slab.style.transform = `perspective(1600px) translateY(${(1 - s.intro) * 70}svh) rotateZ(-7deg) rotateX(${-4 + s.ny * 9}deg) rotateY(${ry}deg)`;
          inner.style.transform = Math.cos((ry * Math.PI) / 180) < 0 ? "rotateY(180deg)" : "";
          faces.forEach((f, k) => (f.style.opacity = k === step ? "1" : "0"));
        }
      }
      s.scene?.frame({ q, nx: s.nx, ny: s.ny, intro: s.intro, t: time });
    };
    gsap.ticker.add(tick);

    return () => {
      gsap.ticker.remove(tick);
      io.disconnect();
      el.removeEventListener("pointermove", move);
      ctx.revert();
    };
  }, [N]);

  // The WebGL scene: only at Full effects with motion allowed. three.js loads on demand, so the other tiers never pay for it.
  useEffect(() => {
    const el = wrap.current!;
    const s = live.current;
    let scene: ReturnType<typeof createSlabScene> | undefined;
    let ro: ResizeObserver | undefined;
    let dead = false;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    // Shows whichever slab was settled on; the first time, plays the entrance.
    const ready = () => {
      if (el.hasAttribute("data-ready")) return;
      el.setAttribute("data-ready", "");
      // Reduced motion: everything is simply there.
      const k = reduce ? 0 : 1;
      gsap.to(s, { intro: 1, duration: 1.9 * k, ease: "expo.out", delay: 0.1 * k });
      gsap.fromTo(el.querySelectorAll("[data-intro]"), { y: 24 * k }, { opacity: 1, y: 0, duration: 1.1 * k, ease: "expo.out", stagger: 0.09 * k, delay: 0.55 * k });
    };

    if (fx !== "full" || reduce) {
      ready();
      return;
    }
    (async () => {
      try {
        const [{ createSlabScene }] = await Promise.all([import("./slabScene"), document.fonts.ready]);
        if (dead) return;
        el.querySelectorAll<HTMLElement>("[data-word]").forEach((w) => (w.style.transform = ""));
        scene = createSlabScene(canvas.current!, el, [null, ...screens.map((x) => x.src)], TINTS, () => setFx("reduced"));
        s.scene = scene;
        el.setAttribute("data-gl", "");
        ro = new ResizeObserver(() => scene!.resize());
        ro.observe(el);
      } catch {
        // No WebGL: the CSS slab stays.
      }
      if (!dead) ready();
    })();

    return () => {
      dead = true;
      ro?.disconnect();
      s.scene = null;
      el.removeAttribute("data-gl");
      scene?.dispose();
    };
  }, [fx, screens]);

  const go = (k: number) => {
    const st = live.current.st;
    if (st) scrollTo(st.start + ((st.end - st.start) * k) / N);
  };

  return (
    <section ref={wrap} className="stage" aria-label="One Dialer">
      <div className="stage-aurora" aria-hidden />
      <canvas ref={canvas} aria-hidden />

      <h1 data-word className="stage-word">
        <span data-seg>
          Calls,
          <i />
        </span>{" "}
        <span data-seg>
          in
          <i />
        </span>
        <br className="max-md:hidden" />{" "}
        <span data-seg className="text-green">
          glass.
          <i />
        </span>
      </h1>
      {screens.map((x) => (
        <p key={x.title} data-word aria-hidden className="stage-word">
          <span data-seg>
            {x.title}
            <i />
          </span>
        </p>
      ))}

      <div data-slab className="slab">
        <div className="absolute inset-0">
          <div data-face aria-hidden className="slab-face flex flex-col justify-end px-[9%] pb-[14%]">
            <div className="grid grid-cols-3 gap-[5%]">
              {[..."123456789*0#"].map((d) => (
                <span key={d} className="grid aspect-[3/2] place-items-center rounded-full bg-white/10 text-[2.4svh] font-semibold max-md:text-[1.5svh]">
                  {d}
                </span>
              ))}
            </div>
            <span className="mx-auto mt-[9%] aspect-[5/2] w-[40%] rounded-full bg-call" />
          </div>
          {screens.map((x, i) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img key={x.src} data-face className="slab-face" src={x.src} alt={`${x.title} screen in One Dialer`} width={720} height={1487} loading={i ? "lazy" : "eager"} decoding="async" />
          ))}
        </div>
      </div>

      <div className="stage-copy">
        <div data-intro className="grid text-[clamp(1.05rem,1.45vw,1.3rem)] leading-[1.4] text-ink-2">
          <p data-cap className="stage-cap">
            A fast, private phone app for Android. Smart T9, call blocking and dual SIM, on true black.
          </p>
          {screens.map((x) => (
            <div key={x.title} data-cap className="stage-cap opacity-0">
              <h2 className="sr-only">{x.title}</h2>
              <p>{x.body}</p>
            </div>
          ))}
        </div>
        <div data-intro className="mt-6">
          <span data-magnetic className="inline-block">
            {RELEASED ? (
              <PlayButton />
            ) : (
              <a href="#join" className="lit press group inline-flex h-14 items-center gap-2.5 rounded-full px-7 text-[16px] font-semibold">
                Join the beta <ArrowRightIcon size={18} weight="bold" className="transition-transform duration-500 ease-settle group-hover:translate-x-1" />
              </a>
            )}
          </span>
          <p className="mt-4 text-[14px] text-ink-3 max-md:hidden">Free · No ads · Android 10 and newer</p>
        </div>
      </div>

      <nav data-intro aria-label="Screens" className="stage-index">
        <ol className="flex flex-col items-end max-md:flex-row">
          {screens.map((x, k) => (
            <li key={x.title}>
              <button
                data-dot
                type="button"
                onClick={() => go(k + 1)}
                className="group grid place-items-center py-1.5 text-[17px] text-ink-3 transition-colors duration-300 hover:text-ink aria-[current]:text-ink max-md:h-11 max-md:w-8 max-md:py-0"
              >
                <span className="max-md:sr-only">{x.title}</span>
                <span aria-hidden className="h-1 w-4 rounded-full bg-white/25 transition-all duration-500 ease-settle group-aria-[current]:w-6 group-aria-[current]:bg-white md:hidden" />
              </button>
            </li>
          ))}
        </ol>
      </nav>
    </section>
  );
}
