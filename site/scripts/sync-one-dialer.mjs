// Refreshes One Dialer's page screens from phone screenshots in the dialer repo
// (../tool/store_graphics/captures/<name>.png): crops the status and gesture bars (PhoneFrame
// draws its own status bar), converts to WebP, and copies the app icon. Run it after taking
// new screenshots, look at the result, then commit.
//
//   npm run sync
import { mkdir, readdir } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const app = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, "..", ".."));
const site = path.resolve(import.meta.dirname, "..");
const captures = path.join(app, "tool", "store_graphics", "captures");
const out = path.join(site, "public", "app");

// Bar heights on the vivo the app is tuned on (1260×2800: status 144 px, gesture bar 54 px),
// as fractions of the width so another phone's captures crop about right.
const STATUS_BAR = 144 / 1260;
const GESTURE_BAR = 54 / 1260;

await mkdir(out, { recursive: true });
const files = (await readdir(captures)).filter((f) => /^\d-[\w-]+\.(png|jpe?g)$/i.test(f));
if (!files.length) throw new Error(`No captures named like 1-calls.png in ${captures}`);

for (const f of files) {
  const img = sharp(path.join(captures, f));
  const { width, height } = await img.metadata();
  const top = Math.round(width * STATUS_BAR);
  const bottom = Math.round(width * GESTURE_BAR);
  await img
    .extract({ left: 0, top, width, height: height - top - bottom })
    .resize({ width: 720 })
    .webp({ quality: 86 })
    .toFile(path.join(out, f.replace(/\.\w+$/, ".webp")));
  console.log(f);
}

await sharp(path.join(app, "assets", "app_icons", "default_phone.png")).png().toFile(path.join(site, "public", "icon.png"));
