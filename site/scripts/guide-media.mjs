// The guides' screenshots and screen recordings (components/Shot.tsx). Drop phone captures into
// public/guide/ named by their slot id (sim-ask.png, recents-tap.mp4, ...), then run
//
//   npm run guide
//
// It crops a screenshot's status and gesture bars (as `npm run sync` does), saves it as WebP and
// removes the original, leaves recordings as they are, and lists every slot the guides use with
// whether it has its own capture yet or still shows the placeholder.
import { readdir, readFile, unlink } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const site = path.resolve(import.meta.dirname, "..");
const dir = path.join(site, "public", "guide");

// Bar heights on the vivo the app is tuned on (1260×2800), as fractions of the width.
const STATUS_BAR = 144 / 1260;
const GESTURE_BAR = 54 / 1260;

for (const f of await readdir(dir)) {
  if (!/\.(png|jpe?g)$/i.test(f)) continue;
  const img = sharp(path.join(dir, f));
  const { width, height } = await img.metadata();
  const top = Math.round(width * STATUS_BAR);
  const bottom = Math.round(width * GESTURE_BAR);
  const out = f.replace(/\.(png|jpe?g)$/i, ".webp");
  await img.extract({ left: 0, top, width, height: height - top - bottom }).resize({ width: 720 }).webp({ quality: 82 }).toFile(path.join(dir, out));
  await unlink(path.join(dir, f));
  console.log(`${f} → ${out}`);
}

// Every slot id in the English dictionary (the other languages use the same ids).
const en = await readFile(path.join(site, "i18n", "en.ts"), "utf8");
const slots = [...new Set([...en.matchAll(/shot: "([\w-]+)"/g)].map((m) => m[1]))];
const files = new Set(await readdir(dir));
const missing = slots.filter((id) => !files.has(`${id}.webp`) && !files.has(`${id}.mp4`));
for (const id of slots) console.log(`${missing.includes(id) ? "✗" : "✓"} ${id}`);
console.log(`\n${slots.length - missing.length} of ${slots.length} slots have their own capture.`);
