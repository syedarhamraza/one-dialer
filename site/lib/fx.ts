"use client";

import { useSyncExternalStore } from "react";

/** The app's Settings › Reduce visual effects, applied to this page: html[data-fx] restyles the glass (globals.css). */
export type Fx = "full" | "reduced" | "off";

const listeners = new Set<() => void>();

export function setFx(fx: Fx) {
  document.documentElement.dataset.fx = fx;
  listeners.forEach((l) => l());
}

export function useFx() {
  return useSyncExternalStore(
    (l) => {
      listeners.add(l);
      return () => listeners.delete(l);
    },
    () => (document.documentElement.dataset.fx as Fx) ?? "full",
    () => "full" as Fx,
  );
}
