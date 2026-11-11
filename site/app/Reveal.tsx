"use client";

import { motion } from "motion/react";

/** Fades and rises its content in once it scrolls into view (MotionConfig drops the rise for reduced motion). */
export function Reveal({ children, delay = 0, className }: { children: React.ReactNode; delay?: number; className?: string }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 28 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ delay, duration: 0.8, ease: [0.2, 0, 0, 1] }}
    >
      {children}
    </motion.div>
  );
}
