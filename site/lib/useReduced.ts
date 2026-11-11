"use client";

import { useSyncExternalStore } from "react";

const QUERY = "(prefers-reduced-motion: reduce)";

function subscribe(cb: () => void) {
  const mq = window.matchMedia(QUERY);
  mq.addEventListener("change", cb);
  return () => mq.removeEventListener("change", cb);
}

/**
 * prefers-reduced-motion, hydration-safe: the server snapshot is false, so the first client render
 * matches the static HTML and the real value arrives on the next render. MotionConfig
 * (components/Providers.tsx) separately stops transform animations for those users.
 */
export function useReduced() {
  return useSyncExternalStore(subscribe, () => window.matchMedia(QUERY).matches, () => false);
}

export function prefersReduced() {
  return typeof window !== "undefined" && window.matchMedia(QUERY).matches;
}
