import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

// A guide's screenshot or screen recording, picked up at build time from public/guide/<id>.mp4 or .webp
// (`npm run guide` crops and converts what's dropped there). Until a slot has its own file it shows the
// placeholder, tagged with the slot id so it's easy to see which capture is still missing.
const DIR = path.join(process.cwd(), "public", "guide");

const find = (id: string, ext: string) => (existsSync(path.join(DIR, `${id}.${ext}`)) ? `${id}.${ext}` : null);

/** The file's public URL, with a hash so a replaced capture under the same name isn't served from caches. */
const url = (file: string) =>
  `/one-dialer/guide/${file}?v=${createHash("md5").update(readFileSync(path.join(DIR, file))).digest("hex").slice(0, 8)}`;

export function Shot({ id, alt, caption }: { id: string; alt: string; caption?: string }) {
  const video = find(id, "mp4");
  const image = find(id, "webp");
  const placeholder = !video && !image;
  // Placeholders alternate between the still and the recording, so both kinds of slot get looked at.
  const usesVideo = video ?? (placeholder && id.length % 2 === 0 ? find("placeholder", "mp4") : null);
  const still = image ?? find("placeholder", "webp");
  return (
    <figure className="shot">
      <div className="shot-frame">
        {usesVideo ? (
          <video src={url(usesVideo)} poster={still ? url(still) : undefined} muted autoPlay loop playsInline preload="metadata" aria-label={alt} />
        ) : still ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={url(still)} alt={alt} loading="lazy" decoding="async" />
        ) : null}
        {placeholder && <span className="shot-tag">Placeholder · {id}</span>}
      </div>
      {caption && <figcaption>{caption}</figcaption>}
    </figure>
  );
}
