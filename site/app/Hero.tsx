"use client";

import { motion, useMotionValue, useScroll, useSpring, useTransform } from "motion/react";
import { Fragment, useRef } from "react";
import { ArrowRightIcon, GooglePlayLogoIcon } from "@phosphor-icons/react";
import { PhoneFrame } from "@/components/PhoneFrame";
import { useReduced } from "@/lib/useReduced";
import { BETA, PLAY_URL } from "./links";

const HEADLINE = ["Your", "calls,", "in", "frosted", "glass."];
const EMPH = new Set(["frosted", "glass."]);
const settle = [0.2, 0, 0, 1] as const;

/** Headline words rise in; the phone floats in, tilts toward the pointer and drifts on scroll. */
export function Hero({ phone }: { phone: string }) {
  const ref = useRef<HTMLElement>(null);
  const reduce = useReduced();
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const rx = useSpring(useTransform(py, [-0.5, 0.5], [6, -6]), { stiffness: 120, damping: 18 });
  const ry = useSpring(useTransform(px, [-0.5, 0.5], [-8, 8]), { stiffness: 120, damping: 18 });
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const phoneY = useTransform(scrollYProgress, [0, 1], [0, -110]);
  const fade = useTransform(scrollYProgress, [0.5, 1], [1, 0]);

  return (
    <section
      ref={ref}
      onPointerMove={(e) => {
        if (reduce || e.pointerType !== "mouse") return;
        const r = e.currentTarget.getBoundingClientRect();
        px.set((e.clientX - r.left) / r.width - 0.5);
        py.set((e.clientY - r.top) / r.height - 0.5);
      }}
      onPointerLeave={() => {
        px.set(0);
        py.set(0);
      }}
      className="relative overflow-x-clip md:min-h-[100dvh]"
    >
      <div className="h-[72px]" />
      <div className="mx-auto grid max-w-[1400px] grid-cols-1 items-center gap-16 px-4 pt-10 pb-28 sm:px-8 md:grid-cols-12 md:pt-12">
        <motion.div style={{ opacity: fade }} className="md:col-span-7">
          <h1 className="text-[clamp(3.1rem,7vw,6.75rem)] leading-[0.93] font-bold tracking-[-0.055em]">
            {HEADLINE.map((w, i) => (
              // The space sits outside the clipped word: an inline-block drops its own trailing space.
              <Fragment key={i}>
                <span className="inline-block overflow-hidden pb-[0.08em] align-bottom">
                <motion.span
                  className={`inline-block ${EMPH.has(w) ? "text-green" : ""}`}
                  initial={{ y: "105%", rotate: 4 }}
                  animate={{ y: 0, rotate: 0 }}
                  transition={{ delay: 0.1 + i * 0.07, duration: 0.9, ease: settle }}
                >
                  {w}
                </motion.span>
                </span>
                {i < HEADLINE.length - 1 && " "}
              </Fragment>
            ))}
          </h1>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.55, duration: 0.8, ease: settle }}
            className="mt-8 max-w-[30ch] text-[clamp(1.12rem,1.5vw,1.35rem)] leading-snug text-ink-2"
          >
            A fast, private phone app for Android. Smart T9, call blocking and dual SIM, on true black with a soft glow.
          </motion.p>
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7, duration: 0.8, ease: settle }}
            className="mt-11 flex flex-wrap items-center gap-3"
          >
            <a
              href={BETA ? "#join" : PLAY_URL}
              className="group inline-flex h-14 items-center gap-2.5 rounded-[var(--radius-pill)] bg-[linear-gradient(180deg,#5fd88a,#2fae5c)] px-7 text-[16px] font-semibold text-black shadow-[0_10px_40px_rgb(0_192_90/0.35),inset_0_1px_0_rgb(255_255_255/0.4)] transition-[transform,box-shadow] hover:shadow-[0_14px_54px_rgb(0_192_90/0.5),inset_0_1px_0_rgb(255_255_255/0.4)] active:scale-[0.97]"
            >
              {BETA ? (
                <>
                  Join the beta <ArrowRightIcon size={18} weight="bold" className="transition-transform group-hover:translate-x-0.5" />
                </>
              ) : (
                <>
                  <GooglePlayLogoIcon size={20} weight="fill" /> Get it on Google Play
                </>
              )}
            </a>
            <a href="#screens" className="inline-flex h-14 items-center rounded-[var(--radius-pill)] px-6 text-[16px] font-semibold transition-colors hover:bg-white/[0.06]">
              See the app
            </a>
          </motion.div>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.9, duration: 0.8 }}
            className="mt-7 text-[14px] text-ink-3"
          >
            Free · No ads · Android 10 and newer
          </motion.p>
        </motion.div>

        <div className="relative md:col-span-5" style={{ perspective: 1400 }}>
          {/* The call screen's aurora behind the device. */}
          <div className="pointer-events-none absolute top-1/2 left-1/2 -z-10 h-[130%] w-[150%] -translate-x-1/2 -translate-y-1/2 bg-[radial-gradient(closest-side_at_60%_40%,rgb(110_60_210/0.42),transparent),radial-gradient(closest-side_at_40%_75%,rgb(0_192_90/0.2),transparent)] blur-2xl" />
          <motion.div style={{ y: phoneY }}>
            <motion.div
              style={{ rotateX: rx, rotateY: ry }}
              initial={{ opacity: 0, y: 120, rotate: -5 }}
              animate={{ opacity: 1, y: 0, rotate: 0 }}
              transition={{ delay: 0.15, duration: 1.1, ease: settle }}
              className="mx-auto w-[min(72vw,340px)] md:mr-0 md:ml-auto lg:mr-[8%]"
            >
              <PhoneFrame src={phone} alt="One Dialer's incoming call screen" priority className="shadow-[0_50px_140px_-30px_rgb(110_60_210/0.55),0_0_0_1px_rgb(255_255_255/0.07)]" />
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
