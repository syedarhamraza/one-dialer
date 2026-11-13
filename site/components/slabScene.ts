import {
  CanvasTexture,
  ExtrudeGeometry,
  Group,
  LinearFilter,
  LinearMipmapLinearFilter,
  LinearSRGBColorSpace,
  Mesh,
  MeshBasicMaterial,
  PerspectiveCamera,
  PlaneGeometry,
  Scene,
  ShaderMaterial,
  Shape,
  Texture,
  TextureLoader,
  Vector2,
  Vector3,
  WebGLRenderer,
  WebGLRenderTarget,
} from "three";

/** What the stage hands the scene every frame. `q` is the step the slab is on (0 = the headline), eased. */
export type SlabFrame = { q: number; nx: number; ny: number; intro: number; t: number };

const FOV = 28;
/** Superellipse exponent of the slab's corners (the app's squircle). */
const SQUIRCLE = 2.6;
const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
// Colours stay in the browser's own sRGB numbers end to end (no linear round trip), so the canvas matches the CSS beside it.
const rgb = (hex: string) => new Vector3(...[1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255));

const AURORA_FRAG = /* glsl */ `
uniform float uT; uniform float uAspect; uniform vec3 uA; uniform vec3 uB; uniform vec2 uPtr;
varying vec2 vUv;
float blob(vec2 c, float r) { vec2 d = (vUv - c) * vec2(uAspect, 1.); return exp(-dot(d, d) / (r * r)); }
void main() {
  vec3 col = uA * blob(vec2(.62, .6) + .05 * vec2(sin(uT * .21), cos(uT * .17)) + uPtr * .03, .44) * .4
           + uB * blob(vec2(.44, .22) + .06 * vec2(cos(uT * .13), sin(uT * .19)) - uPtr * .02, .38) * .26
           + uA * blob(vec2(.1 + .08 * sin(uT * .1), .9), .3) * .1;
  // A grain of noise, so the dark gradient doesn't band.
  col += (fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) - .5) / 170.;
  gl_FragColor = vec4(col, 1.);
}`;

// The slab reads what's behind it (the aurora and the giant words, rendered to uBack first) and bends it by its
// own surface normal. The normal is worked out from the shape itself, not the mesh, so the faces stay optically
// flat and only the rim acts as a lens.
const SLAB_FRAG = /* glsl */ `
uniform sampler2D uBack; uniform vec2 uRes; uniform vec3 uHalf; uniform float uR; uniform float uBev; uniform float uRim; uniform float uFrost;
uniform mat3 normalMatrix;
varying vec3 vObj; varying vec3 vView;
vec3 surfaceNormal(vec3 p) {
  vec2 q = abs(p.xy) - uHalf.xy + uR;
  float d; vec2 g;
  if (q.x > 0. && q.y > 0.) {
    d = pow(pow(q.x, ${SQUIRCLE.toFixed(1)}) + pow(q.y, ${SQUIRCLE.toFixed(1)}), ${(1 / SQUIRCLE).toFixed(4)}) - uR;
    g = normalize(pow(q, vec2(${(SQUIRCLE - 1).toFixed(1)}))) * sign(p.xy);
  } else if (q.x > q.y) { d = q.x - uR; g = vec2(sign(p.x), 0.); }
  else { d = q.y - uR; g = vec2(0., sign(p.y)); }
  float lens = pow(clamp((d + uRim) / uRim, 0., 1.), 3.);
  float side = max(d + uBev, 0.) / uBev;
  float cap = max(abs(p.z) - (uHalf.z - uBev), 0.) / uBev;
  return normalize(vec3(g * max(side, lens * 1.25), sign(p.z) * max(cap, .0001)));
}
void main() {
  vec3 n = normalize(normalMatrix * surfaceNormal(vObj));
  vec3 v = normalize(-vView);
  float ndv = clamp(dot(n, v), 0., 1.);
  vec2 uv = gl_FragCoord.xy / uRes;
  vec2 bend = -n.xy * .1 * vec2(uRes.y / uRes.x, 1.);
  float lod = uFrost + (1. - ndv) * 2.5;
  // Red, green and blue bend a little differently: a fringe of colour along every refracted edge.
  vec3 col = vec3(
    textureLod(uBack, uv + bend * .9, lod).r,
    textureLod(uBack, uv + bend, lod).g,
    textureLod(uBack, uv + bend * 1.1, lod).b);
  col = col * .94 + vec3(.03, .031, .036);
  col += pow(1. - ndv, 2.6) * vec3(.5, .55, .66) * .7;
  col += pow(max(dot(reflect(-normalize(vec3(-.35, .8, .5)), n), v), 0.), 28.) * .55;
  gl_FragColor = vec4(col, 1.);
}`;

/** The slab's outline: a rectangle with superellipse corners, anticlockwise. */
function squircle(w: number, h: number, r: number) {
  const pts: Vector2[] = [];
  const corner = (sx: number, sy: number, flip: boolean) => {
    for (let i = 0; i <= 20; i++) {
      const t = ((flip ? 20 - i : i) / 20) * (Math.PI / 2);
      pts.push(
        new Vector2(sx * (w / 2 - r + r * Math.cos(t) ** (2 / SQUIRCLE)), sy * (h / 2 - r + r * Math.sin(t) ** (2 / SQUIRCLE))),
      );
    }
  };
  corner(1, 1, false);
  corner(-1, 1, true);
  corner(-1, -1, false);
  corner(1, -1, true);
  return new Shape(pts);
}

/** The headline step's face: the keypad's frosted keys and its lit Call key, seen through clear glass. */
function keysTexture() {
  const c = document.createElement("canvas");
  c.width = 512;
  c.height = 1024;
  const g = c.getContext("2d")!;
  g.textAlign = "center";
  g.textBaseline = "middle";
  g.font = "600 40px system-ui, sans-serif";
  [..."123456789*0#"].forEach((d, i) => {
    const x = 46 + (i % 3) * 147;
    const y = 440 + Math.floor(i / 3) * 100;
    g.beginPath();
    g.roundRect(x, y, 126, 82, 41);
    g.fillStyle = "rgb(255 255 255 / 0.1)";
    g.fill();
    g.strokeStyle = "rgb(255 255 255 / 0.2)";
    g.stroke();
    g.fillStyle = "rgb(255 255 255 / 0.85)";
    g.fillText(d, x + 63, y + 43);
  });
  g.shadowColor = "rgb(0 194 22 / 0.8)";
  g.shadowBlur = 40;
  g.beginPath();
  g.roundRect(156, 860, 200, 84, 42);
  g.fillStyle = "#00c216";
  g.fill();
  return new CanvasTexture(c);
}

/** Crops a texture to cover a plane of the given aspect (width / height), like object-fit: cover. */
function cover(tex: Texture, aspect: number) {
  const img = tex.image as { width: number; height: number };
  const ta = img.width / img.height;
  if (ta > aspect) tex.repeat.set(aspect / ta, 1);
  else tex.repeat.set(1, ta / aspect);
  tex.offset.set((1 - tex.repeat.x) / 2, (1 - tex.repeat.y) / 2);
}

/**
 * Draws the stage in WebGL: the aurora, the giant words (copied from the DOM words' own positions and font, so the
 * layout stays in CSS), and the glass slab refracting both. `faces[0]` is the headline step and has no screenshot.
 * Throws when WebGL isn't available.
 */
export function createSlabScene(
  canvas: HTMLCanvasElement,
  stage: HTMLElement,
  faces: (string | null)[],
  tints: [string, string][],
  onSlow: () => void,
) {
  const coarse = matchMedia("(pointer: coarse)").matches;
  const renderer = new WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
  renderer.outputColorSpace = LinearSRGBColorSpace;
  const dpr = Math.min(devicePixelRatio, coarse ? 1.5 : 2);
  renderer.setPixelRatio(dpr);
  // Phones refract a half-size copy of the backdrop: a quarter of the pixels, and frosted glass hides the difference.
  const backScale = coarse ? 0.5 : 1;

  const scene = new Scene();
  // The camera sits where one world unit at z = 0 is one CSS pixel, so DOM boxes map straight into the scene.
  const camera = new PerspectiveCamera(FOV, 1, 10, 20000);
  const back = new WebGLRenderTarget(1, 1, { depthBuffer: false });
  back.texture.generateMipmaps = true;
  back.texture.minFilter = LinearMipmapLinearFilter;

  const colors = tints.map(([a, b]) => [rgb(a), rgb(b)] as const);
  const aurora = new ShaderMaterial({
    depthTest: false,
    depthWrite: false,
    uniforms: { uT: { value: 0 }, uAspect: { value: 1 }, uA: { value: new Vector3() }, uB: { value: new Vector3() }, uPtr: { value: new Vector2() } },
    vertexShader: "varying vec2 vUv; void main() { vUv = position.xy * .5 + .5; gl_Position = vec4(position.xy, 0., 1.); }",
    fragmentShader: AURORA_FRAG,
  });
  const sky = new Mesh(new PlaneGeometry(2, 2), aurora);
  sky.frustumCulled = false;
  sky.renderOrder = -10;
  scene.add(sky);

  const glass = new ShaderMaterial({
    // Flagged transparent only so it sorts after the words (which are); it writes depth and is fully opaque.
    transparent: true,
    depthWrite: true,
    uniforms: {
      uBack: { value: back.texture },
      uRes: { value: new Vector2() },
      uHalf: { value: new Vector3() },
      uR: { value: 1 },
      uBev: { value: 1 },
      uRim: { value: 1 },
      uFrost: { value: coarse ? 1.2 : 2.2 },
    },
    vertexShader:
      "varying vec3 vObj; varying vec3 vView; void main() { vObj = position; vec4 mv = modelViewMatrix * vec4(position, 1.); vView = mv.xyz; gl_Position = projectionMatrix * mv; }",
    fragmentShader: SLAB_FRAG,
  });
  const slab = new Group();
  slab.rotation.order = "ZXY";
  const body = new Mesh(undefined, glass);
  const mask = new CanvasTexture(document.createElement("canvas"));
  const faceMat = new MeshBasicMaterial({ alphaMap: mask, transparent: true, depthWrite: false });
  const front = new Mesh(undefined, faceMat);
  const rear = new Mesh(undefined, faceMat);
  rear.rotation.y = Math.PI;
  front.renderOrder = rear.renderOrder = 1;
  slab.add(body, front, rear);
  scene.add(slab);

  const loader = new TextureLoader();
  let faceAspect = 0.5;
  const textures = faces.map((src) => (src ? loader.load(src, (t) => cover(t, faceAspect)) : keysTexture()));

  type Word = { mesh: Mesh<PlaneGeometry, MeshBasicMaterial>; k: number; j: number; y: number; size: number };
  let words: Word[] = [];
  let W = 0;
  let H = 0;
  let cx = 0;
  let cy = 0;

  function clearWords() {
    for (const w of words) {
      scene.remove(w.mesh);
      w.mesh.geometry.dispose();
      w.mesh.material.map?.dispose();
      w.mesh.material.dispose();
    }
    words = [];
  }

  function buildWords() {
    clearWords();
    const sr = stage.getBoundingClientRect();
    stage.querySelectorAll<HTMLElement>("[data-word]").forEach((el, k) => {
      el.querySelectorAll<HTMLElement>("[data-seg]").forEach((seg, j) => {
        const cs = getComputedStyle(seg);
        const size = parseFloat(cs.fontSize);
        const r = seg.getBoundingClientRect();
        const baseline = seg.querySelector("i")!.getBoundingClientRect().bottom;
        const pad = Math.ceil(size * 0.3);
        const w = Math.ceil(r.width) + pad * 2;
        const h = Math.ceil(size * 1.3) + pad * 2;
        const c = document.createElement("canvas");
        c.width = w * dpr;
        c.height = h * dpr;
        const g = c.getContext("2d")!;
        g.scale(dpr, dpr);
        g.font = `${cs.fontWeight} ${size}px ${cs.fontFamily}`;
        g.fillStyle = cs.color;
        const spacing = parseFloat(cs.letterSpacing) || 0;
        const text = seg.textContent ?? "";
        if ("letterSpacing" in g) {
          g.letterSpacing = `${spacing}px`;
          g.fillText(text, pad, pad + size);
        } else {
          // Safari before 17.4 has no canvas letter-spacing: place the letters one by one.
          let x = pad;
          for (const ch of text) {
            (g as CanvasRenderingContext2D).fillText(ch, x, pad + size);
            x += (g as CanvasRenderingContext2D).measureText(ch).width + spacing;
          }
        }
        const map = new CanvasTexture(c);
        map.generateMipmaps = false;
        map.minFilter = LinearFilter;
        const mesh = new Mesh(new PlaneGeometry(w, h), new MeshBasicMaterial({ map, transparent: true, depthTest: false, depthWrite: false }));
        mesh.renderOrder = -5;
        const left = r.left - sr.left - pad;
        const top = baseline - sr.top - pad - size;
        mesh.position.x = left + w / 2 - W / 2;
        scene.add(mesh);
        words.push({ mesh, k, j, y: H / 2 - (top + h / 2), size });
      });
    });
  }

  function buildSlab() {
    const el = stage.querySelector<HTMLElement>("[data-slab]")!;
    const w = el.offsetWidth;
    const h = el.offsetHeight;
    cx = el.offsetLeft + w / 2 - W / 2;
    cy = H / 2 - (el.offsetTop + h / 2);
    const r = w * 0.17;
    const depth = w * 0.085;
    const bevel = depth * 0.46;
    body.geometry.dispose();
    body.geometry = new ExtrudeGeometry(squircle(w, h, r), {
      depth: depth - bevel * 2,
      bevelThickness: bevel,
      bevelSize: bevel,
      bevelOffset: -bevel,
      bevelSegments: 8,
    }).center();
    glass.uniforms.uHalf.value.set(w / 2, h / 2, depth / 2);
    glass.uniforms.uR.value = r;
    glass.uniforms.uBev.value = bevel;
    glass.uniforms.uRim.value = w * 0.1;

    const inset = w * 0.032;
    const fw = w - inset * 2;
    const fh = h - inset * 2;
    faceAspect = fw / fh;
    front.geometry.dispose();
    front.geometry = rear.geometry = new PlaneGeometry(fw, fh);
    front.position.z = depth / 2 + 0.6;
    rear.position.z = -front.position.z;
    for (const t of textures) if (t.image) cover(t, faceAspect);
    // The face's rounded corners, as an alpha mask.
    const m = mask.image as HTMLCanvasElement;
    m.width = 256;
    m.height = Math.round(256 / faceAspect);
    const g = m.getContext("2d")!;
    g.fillStyle = "#000";
    g.fillRect(0, 0, m.width, m.height);
    g.fillStyle = "#fff";
    g.beginPath();
    g.roundRect(0, 0, m.width, m.height, ((r - inset) / fw) * m.width);
    g.fill();
    mask.needsUpdate = true;
  }

  function resize() {
    const w = stage.clientWidth;
    const h = stage.clientHeight;
    if (w === W && h === H) return;
    W = w;
    H = h;
    renderer.setSize(W, H, false);
    back.setSize(Math.round(W * dpr * backScale), Math.round(H * dpr * backScale));
    renderer.getDrawingBufferSize(glass.uniforms.uRes.value);
    camera.aspect = W / H;
    camera.position.z = H / (2 * Math.tan((FOV * Math.PI) / 360));
    camera.updateProjectionMatrix();
    aurora.uniforms.uAspect.value = W / H;
    buildWords();
    buildSlab();
  }
  resize();

  // If the first seconds run under ~30 fps, hand the page to Reduced effects, as the app would on that chip.
  let last = 0;
  let samples = 0;
  let total = 0;

  function frame(f: SlabFrame) {
    const now = performance.now();
    const dt = now - last;
    last = now;
    if (f.intro === 1 && samples < 90 && dt < 250) {
      total += dt;
      if (++samples === 90 && total / 90 > 33) onSlow();
    }

    const out = 1 - f.intro;
    slab.position.set(cx, cy + Math.sin(f.t * 0.7) * 5 - out * H * 0.7, 0);
    slab.rotation.set(-0.07 + f.ny * 0.16 + Math.sin(f.t * 0.5) * 0.015, 0.34 + f.q * Math.PI + f.nx * 0.26 - out * 1.7, -0.12);
    const face = textures[Math.round(f.q)];
    if (faceMat.map !== face) {
      faceMat.map = face;
      faceMat.needsUpdate = true;
    }

    for (const w of words) {
      const d = w.k - f.q;
      // The headline's words rise in one after another on load.
      const rise = w.k === 0 ? clamp01(f.intro * 1.5 - w.j * 0.18) : 1;
      const a = clamp01(1 - Math.abs(d) * 2) * rise;
      w.mesh.visible = a > 0.002;
      w.mesh.material.opacity = a;
      w.mesh.position.y = w.y - d * w.size * 0.9 - (1 - rise) * w.size * 0.3;
    }

    const i = Math.min(Math.floor(f.q), colors.length - 2);
    aurora.uniforms.uA.value.lerpVectors(colors[i][0], colors[i + 1][0], f.q - i);
    aurora.uniforms.uB.value.lerpVectors(colors[i][1], colors[i + 1][1], f.q - i);
    aurora.uniforms.uT.value = f.t;
    aurora.uniforms.uPtr.value.set(f.nx, -f.ny);

    slab.visible = false;
    renderer.setRenderTarget(back);
    renderer.render(scene, camera);
    slab.visible = true;
    renderer.setRenderTarget(null);
    renderer.render(scene, camera);
  }

  function dispose() {
    clearWords();
    for (const t of textures) t.dispose();
    for (const m of [sky, body, front]) m.geometry.dispose();
    mask.dispose();
    aurora.dispose();
    glass.dispose();
    faceMat.dispose();
    back.dispose();
    renderer.dispose();
  }

  return { frame, resize, dispose };
}
