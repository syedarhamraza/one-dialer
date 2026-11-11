"use client";

import { createContext, useContext, useState } from "react";
import { MotionConfig } from "motion/react";

type Site = {
  /** True once the intro has finished (or was skipped), so the hero can start its entrance. */
  introDone: boolean;
  setIntroDone: (v: boolean) => void;
  /** Settings › Appearance › 3D floating elements, demoed by the customizer and applied to the page's own chrome. */
  float3d: boolean;
  setFloat3d: (v: boolean) => void;
};

const SiteContext = createContext<Site>({
  introDone: true,
  setIntroDone: () => {},
  float3d: false,
  setFloat3d: () => {},
});

export const useSite = () => useContext(SiteContext);

export function Providers({ children }: { children: React.ReactNode }) {
  const [introDone, setIntroDone] = useState(false);
  const [float3d, setFloat3d] = useState(false);
  return (
    <SiteContext.Provider value={{ introDone, setIntroDone, float3d, setFloat3d }}>
      <MotionConfig reducedMotion="user">{children}</MotionConfig>
    </SiteContext.Provider>
  );
}
