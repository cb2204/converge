#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  mkdirSync,
  readdirSync,
  readFileSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, "..");

const colors = {
  black: "#070A0F",
  carbon: "#111720",
  graphite: "#29313A",
  steel: "#8D99A6",
  ivory: "#F5F2EA",
  white: "#FFFFFF",
  gold: "#F3B64C",
  mint: "#73E2C3",
  coral: "#FF6B64",
};

const ensure = (path) => mkdirSync(path, { recursive: true });
const write = (path, body) => {
  ensure(dirname(path));
  writeFileSync(path, body);
};

const xml = (width, height, body, title) => `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title">
  <title id="title">${title}</title>
  ${body}
</svg>
`;

const markPath =
  "M512 72 L832 256 L832 332 L714 400 L714 338 L512 222 L310 338 L310 570 L512 686 L714 570 L714 510 L832 442 L832 652 L512 836 L192 652 L192 256 Z";
const foldPath = "M714 188 L832 256 L714 324 Z";

const mark = ({
  body = colors.black,
  accent = colors.gold,
  transform = "",
  opacity = 1,
  outline = false,
} = {}) => {
  const paint = outline
    ? `fill="none" stroke="${body}" stroke-width="12"`
    : `fill="${body}" stroke="${body}" stroke-width="20"`;
  const foldPaint = outline
    ? `fill="none" stroke="${accent}" stroke-width="12"`
    : `fill="${accent}" stroke="${accent}" stroke-width="12"`;
  return `<g transform="${transform}" opacity="${opacity}" stroke-linejoin="round">
    <path d="${markPath}" ${paint}/>
    <path d="${foldPath}" ${foldPaint}/>
  </g>`;
};

const glyphs = {
  C: "M82 18 H24 V102 H82",
  O: "M26 18 H78 V102 H26 Z",
  N: "M22 102 V18 L80 102 V18",
  V: "M18 18 L50 102 L82 18",
  E: "M82 18 H24 V102 H82 M24 60 H72",
  R: "M22 102 V18 H72 V58 H22 M57 58 L84 102",
  G: "M82 36 V18 H24 V102 H82 V64 H58",
};

const wordmark = ({
  color = colors.black,
  x = 0,
  y = 0,
  scale = 1,
  tracking = 38,
  opacity = 1,
} = {}) => {
  const letters = [..."CONVERGE"];
  let cursor = 0;
  const paths = letters
    .map((letter) => {
      const out = `<path d="${glyphs[letter]}" transform="translate(${cursor} 0)"/>`;
      cursor += 100 + tracking;
      return out;
    })
    .join("\n");
  return `<g transform="translate(${x} ${y}) scale(${scale})" fill="none" stroke="${color}" stroke-width="15" stroke-linecap="square" stroke-linejoin="round" opacity="${opacity}">
    ${paths}
  </g>`;
};

const transparentIconSvg = (body, accent, title) =>
  xml(1024, 1024, mark({ body, accent }), title);

const lockupSvg = (body, accent, title) =>
  xml(
    2048,
    512,
    `${mark({ body, accent, transform: "translate(68 42) scale(0.42)" })}
     ${wordmark({ color: body, x: 560, y: 176, scale: 1.18, tracking: 36 })}`,
    title,
  );

const appIconSvg = ({ background, body, accent, maskable = false, title }) =>
  xml(
    1024,
    1024,
    `<rect width="1024" height="1024" rx="${maskable ? 0 : 224}" fill="${background}"/>
     ${mark({
       body,
       accent,
       transform: maskable ? "translate(128 128) scale(0.75)" : "translate(96 96) scale(0.81)",
     })}`,
    title,
  );

const backgroundIconSvg = ({ background, body, accent, title }) =>
  xml(
    1200,
    1200,
    `<rect width="1200" height="1200" fill="${background}"/>
     ${mark({ body, accent, transform: "translate(88 88)" })}`,
    title,
  );

const backgroundLockupSvg = ({ background, body, accent, title }) =>
  xml(
    1800,
    600,
    `<rect width="1800" height="600" fill="${background}"/>
     ${mark({ body, accent, transform: "translate(90 86) scale(0.42)" })}
     ${wordmark({ color: body, x: 560, y: 210, scale: 1.08, tracking: 34 })}`,
    title,
  );

const gridPattern = (width, height, color = colors.ivory) => {
  const vertical = [];
  const horizontal = [];
  for (let x = 0; x <= width; x += 64) {
    vertical.push(`<path d="M${x} 0V${height}"/>`);
  }
  for (let y = 0; y <= height; y += 64) {
    horizontal.push(`<path d="M0 ${y}H${width}"/>`);
  }
  return `<g stroke="${color}" stroke-width="1" opacity="0.045">${vertical.join("")}${horizontal.join("")}</g>`;
};

const lineage = (width, height, endX, endY, color = colors.gold) => {
  const paths = [];
  const count = 14;
  for (let index = 0; index < count; index += 1) {
    const y = 50 + index * ((height - 100) / (count - 1));
    const controlA = width * (0.28 + (index % 3) * 0.035);
    const controlB = width * (0.58 - (index % 4) * 0.02);
    paths.push(
      `<path d="M0 ${y.toFixed(1)} C${controlA.toFixed(1)} ${y.toFixed(1)}, ${controlB.toFixed(1)} ${endY.toFixed(1)}, ${endX} ${endY}" opacity="${(0.14 + index * 0.018).toFixed(2)}"/>`,
    );
  }
  return `<g fill="none" stroke="${color}" stroke-width="2">${paths.join("")}</g>`;
};

const socialSvg = ({ width, height, background, body, accent, title, compact = false }) => {
  const markScale = compact ? 0.26 : 0.34;
  const markX = compact ? width - 340 : width - 450;
  const markY = (height - 1024 * markScale) / 2;
  const wordScale = compact ? 0.58 : 0.52;
  const wordY = compact ? height * 0.21 : height * 0.24;
  return xml(
    width,
    height,
    `<rect width="${width}" height="${height}" fill="${background}"/>
     ${gridPattern(width, height, body)}
     ${lineage(width * 0.58, height, width * 0.52, height * 0.5, accent)}
     ${wordmark({ color: body, x: 88, y: wordY, scale: wordScale, tracking: 34 })}
     <text x="92" y="${height * 0.64}" fill="${body}" font-family="Avenir Next" font-size="${compact ? 30 : 38}" font-weight="500">Compile intent into shipped software.</text>
     <text x="92" y="${height * 0.78}" fill="${accent}" font-family="Menlo" font-size="${compact ? 18 : 22}" letter-spacing="3">DONE IS PROVEN.</text>
     ${mark({ body, accent, transform: `translate(${markX} ${markY}) scale(${markScale})` })}`,
    title,
  );
};

const overviewSvg = () => {
  const panel = (x, y, w, h, fill, body) =>
    `<g transform="translate(${x} ${y})"><rect width="${w}" height="${h}" rx="28" fill="${fill}"/>${body}</g>`;
  const label = (text, x, y, color = colors.steel) =>
    `<text x="${x}" y="${y}" fill="${color}" font-family="Menlo" font-size="18" letter-spacing="2.5">${text}</text>`;

  const palette = [
    ["FACTORY BLACK", colors.black],
    ["PROOF IVORY", colors.ivory],
    ["FORGE GOLD", colors.gold],
    ["SETTLEMENT MINT", colors.mint],
    ["VERDICT CORAL", colors.coral],
  ]
    .map(
      ([name, color], index) =>
        `<g transform="translate(${42 + index * 134} 120)"><rect width="108" height="96" rx="14" fill="${color}"/><text x="0" y="244" fill="${colors.steel}" font-family="Menlo" font-size="12">${name}</text><text x="0" y="264" fill="${colors.ivory}" font-family="Menlo" font-size="13">${color}</text></g>`,
    )
    .join("");

  return xml(
    2400,
    1500,
    `<rect width="2400" height="1500" fill="#030507"/>
     ${label("CONVERGE / BRAND SYSTEM 01", 56, 40, colors.ivory)}
     ${label("SETTLEMENT FOLD", 2056, 40, colors.gold)}

     ${panel(
       48,
       72,
       760,
       420,
       colors.black,
       `${mark({ body: colors.ivory, accent: colors.gold, transform: "translate(48 54) scale(0.32)" })}
        ${wordmark({ color: colors.ivory, x: 330, y: 154, scale: 0.40, tracking: 30 })}
        ${label("PRIMARY MARK", 330, 270)}
        ${label("CONTROLLED AUTONOMY", 330, 306, colors.gold)}`,
     )}

     ${panel(
       830,
       72,
       760,
       420,
       colors.ivory,
       `${label("CONSTRUCTION / ONE CONTINUOUS FOLD", 34, 42, colors.graphite)}
        <g transform="translate(88 58)">${mark({ body: colors.graphite, accent: colors.gold, transform: "scale(0.31)", outline: true })}
        <g stroke="${colors.gold}" stroke-width="1.4" opacity="0.7"><circle cx="160" cy="160" r="126" fill="none"/><path d="M14 160H330M160 14V330M50 50L270 270M270 50L50 270"/></g></g>
        <text x="426" y="152" fill="${colors.black}" font-family="Avenir Next" font-size="24" font-weight="600">BOUNDARY</text>
        <text x="426" y="194" fill="${colors.graphite}" font-family="Menlo" font-size="16">the governed loop</text>
        <text x="426" y="258" fill="${colors.black}" font-family="Avenir Next" font-size="24" font-weight="600">FOLD</text>
        <text x="426" y="300" fill="${colors.graphite}" font-family="Menlo" font-size="16">the closing proof</text>
        <path d="M408 214H692" stroke="${colors.gold}" stroke-width="2"/>`,
     )}

     ${panel(
       1612,
       72,
       740,
       420,
       colors.carbon,
       `${label("COMMAND SURFACE", 34, 42)}
        <rect x="34" y="74" width="672" height="292" rx="18" fill="${colors.black}" stroke="${colors.graphite}"/>
        <circle cx="64" cy="100" r="6" fill="${colors.coral}"/><circle cx="86" cy="100" r="6" fill="${colors.gold}"/><circle cx="108" cy="100" r="6" fill="${colors.mint}"/>
        <text x="64" y="156" fill="${colors.steel}" font-family="Menlo" font-size="16">$ cvg loop --issue T-042</text>
        <text x="64" y="204" fill="${colors.ivory}" font-family="Menlo" font-size="16">attempt → verify → repeat</text>
        <text x="64" y="264" fill="${colors.mint}" font-family="Menlo" font-size="20">TASK_LOOP=SETTLED</text>
        <text x="64" y="312" fill="${colors.steel}" font-family="Menlo" font-size="13">receipt / sha256:e7a1…9f3c</text>
        ${mark({ body: colors.ivory, accent: colors.mint, transform: "translate(530 116) scale(0.13)" })}`,
     )}

     ${panel(
       48,
       516,
       760,
       420,
       "#0A0E14",
       `${label("BRAND ESSENCE", 34, 42)}
        <text x="42" y="188" fill="${colors.ivory}" font-family="Avenir Next" font-size="70" font-weight="600">Done is</text>
        <text x="42" y="270" fill="${colors.gold}" font-family="Avenir Next" font-size="70" font-weight="600">proven.</text>
        <path d="M42 324H420" stroke="${colors.gold}" stroke-width="3"/>
        ${label("NOT CLAIMED BY THE AGENT", 42, 366)}`,
     )}

     ${panel(
       830,
       516,
       760,
       420,
       colors.carbon,
       `${label("COLOR SYSTEM", 34, 42)}${palette}`,
     )}

     ${panel(
       1612,
       516,
       740,
       420,
       colors.ivory,
       `${label("CUSTOM WORDMARK / DATA MONO", 34, 42, colors.graphite)}
        ${wordmark({ color: colors.black, x: 42, y: 108, scale: 0.56, tracking: 30 })}
        <path d="M42 272H698" stroke="${colors.gold}" stroke-width="2"/>
        <text x="42" y="330" fill="${colors.black}" font-family="Menlo" font-size="18">ABCDEFGHIJKLMNOPQRSTUVWXYZ</text>
        <text x="42" y="370" fill="${colors.graphite}" font-family="Menlo" font-size="16">0123456789  {} [] / --json</text>`,
     )}

     ${panel(
       48,
       960,
       760,
       476,
       colors.carbon,
       `${label("DIGITAL ICON", 34, 42)}
        <rect x="70" y="96" width="300" height="300" rx="70" fill="${colors.black}"/>
        ${mark({ body: colors.ivory, accent: colors.gold, transform: "translate(94 120) scale(0.25)" })}
        <rect x="414" y="96" width="240" height="240" rx="54" fill="${colors.ivory}"/>
        ${mark({ body: colors.black, accent: colors.gold, transform: "translate(432 114) scale(0.20)" })}
        ${label("DARK", 164, 432)}${label("LIGHT", 496, 372, colors.ivory)}`,
     )}

     ${panel(
       830,
       960,
       760,
       476,
       colors.black,
       `${label("CINEMATIC LINEAGE", 34, 42)}
        ${gridPattern(760, 476, colors.ivory)}
        ${lineage(520, 350, 506, 222, colors.gold)}
        ${mark({ body: colors.ivory, accent: colors.gold, transform: "translate(484 98) scale(0.24)" })}
        ${label("INTENT", 34, 420)}${label("SETTLED", 610, 420, colors.gold)}`,
     )}

     ${panel(
       1612,
       960,
       740,
       476,
       colors.carbon,
       `${label("PROOF STATES", 34, 42)}
        ${mark({ body: colors.ivory, accent: colors.mint, transform: "translate(32 74) scale(0.12)" })}
        <text x="170" y="154" fill="${colors.mint}" font-family="Menlo" font-size="26">SETTLED</text>
        <text x="170" y="188" fill="${colors.steel}" font-family="Menlo" font-size="14">verified / shipped</text>
        <path d="M34 232H706" stroke="${colors.graphite}"/>
        ${mark({ body: colors.ivory, accent: colors.gold, transform: "translate(32 228) scale(0.12)" })}
        <text x="170" y="308" fill="${colors.gold}" font-family="Menlo" font-size="26">BOUND</text>
        <text x="170" y="342" fill="${colors.steel}" font-family="Menlo" font-size="14">proving / not settled</text>
        <path d="M34 386H706" stroke="${colors.graphite}"/>
        <rect x="548" y="405" width="158" height="38" rx="19" fill="${colors.coral}" opacity="0.12"/>
        <text x="570" y="431" fill="${colors.coral}" font-family="Menlo" font-size="15">RED / REFUSED</text>`,
     )}`,
    "Converge Settlement Fold brand-system overview",
  );
};

const svgDir = join(root, "00-source", "svg");
ensure(svgDir);

const masters = {
  "converge-icon-color-dark.svg": transparentIconSvg(
    colors.black,
    colors.gold,
    "Converge full-color icon for light surfaces",
  ),
  "converge-icon-color-light.svg": transparentIconSvg(
    colors.ivory,
    colors.gold,
    "Converge full-color icon for dark surfaces",
  ),
  "converge-lockup-color-dark.svg": lockupSvg(
    colors.black,
    colors.gold,
    "Converge full-color lockup for light surfaces",
  ),
  "converge-lockup-color-light.svg": lockupSvg(
    colors.ivory,
    colors.gold,
    "Converge full-color lockup for dark surfaces",
  ),
  "converge-icon-black.svg": transparentIconSvg(colors.black, colors.black, "Converge black icon"),
  "converge-lockup-black.svg": lockupSvg(colors.black, colors.black, "Converge black lockup"),
  "converge-icon-white.svg": transparentIconSvg(colors.white, colors.white, "Converge white icon"),
  "converge-lockup-white.svg": lockupSvg(colors.white, colors.white, "Converge white lockup"),
  "converge-icon-gold.svg": transparentIconSvg(colors.gold, colors.gold, "Converge gold icon"),
  "converge-lockup-gold.svg": lockupSvg(colors.gold, colors.gold, "Converge gold lockup"),
  "converge-icon-graphite.svg": transparentIconSvg(
    colors.graphite,
    colors.graphite,
    "Converge graphite icon",
  ),
  "converge-lockup-graphite.svg": lockupSvg(
    colors.graphite,
    colors.graphite,
    "Converge graphite lockup",
  ),
};

for (const [name, body] of Object.entries(masters)) {
  write(join(svgDir, name), body);
}

const copyText = (from, to) => write(to, readFileSync(from, "utf8"));

const primaryDir = join(root, "01-primary", "color");
for (const name of [
  "converge-icon-color-dark.svg",
  "converge-icon-color-light.svg",
  "converge-lockup-color-dark.svg",
  "converge-lockup-color-light.svg",
]) {
  copyText(join(svgDir, name), join(primaryDir, name));
}

const monoMap = {
  black: ["converge-icon-black.svg", "converge-lockup-black.svg"],
  white: ["converge-icon-white.svg", "converge-lockup-white.svg"],
  gold: ["converge-icon-gold.svg", "converge-lockup-gold.svg"],
  graphite: ["converge-icon-graphite.svg", "converge-lockup-graphite.svg"],
};
for (const [tone, names] of Object.entries(monoMap)) {
  for (const name of names) {
    copyText(join(svgDir, name), join(root, "02-monochrome", tone, name));
  }
}

const renderPng = (source, output, resize = null) => {
  ensure(dirname(output));
  const rendered = `${output}.native-render.png`;
  execFileSync("sips", ["-s", "format", "png", source, "--out", rendered], {
    stdio: "ignore",
  });
  if (resize) {
    execFileSync("magick", [rendered, "-resize", resize, `PNG32:${output}`], {
      stdio: "inherit",
    });
    rmSync(rendered);
  } else {
    rmSync(output, { force: true });
    renameSync(rendered, output);
  }
};

const renderWebp = (source, output, resize = null) => {
  ensure(dirname(output));
  const rendered = `${output}.native-render.png`;
  execFileSync("sips", ["-s", "format", "png", source, "--out", rendered], {
    stdio: "ignore",
  });
  const args = [rendered];
  if (resize) args.push("-resize", resize);
  args.push("-define", "webp:lossless=true", output);
  execFileSync("magick", args, { stdio: "inherit" });
  rmSync(rendered);
};

for (const name of [
  "converge-icon-color-dark",
  "converge-icon-color-light",
  "converge-lockup-color-dark",
  "converge-lockup-color-light",
]) {
  renderPng(join(primaryDir, `${name}.svg`), join(primaryDir, `${name}.png`));
}

for (const [tone, names] of Object.entries(monoMap)) {
  for (const name of names) {
    renderPng(
      join(root, "02-monochrome", tone, name),
      join(root, "02-monochrome", tone, name.replace(".svg", ".png")),
    );
  }
}

const surfaces = [
  ["factory-black", colors.black, colors.ivory, colors.gold],
  ["carbon", colors.carbon, colors.ivory, colors.gold],
  ["forge-gold", colors.gold, colors.black, colors.ivory],
  ["proof-ivory", colors.ivory, colors.black, colors.gold],
  ["white", colors.white, colors.black, colors.gold],
];
for (const [slug, background, body, accent] of surfaces) {
  const iconSource = join(root, "00-source", "generated", `icon-on-${slug}.svg`);
  const lockupSource = join(root, "00-source", "generated", `lockup-on-${slug}.svg`);
  write(
    iconSource,
    backgroundIconSvg({
      background,
      body,
      accent,
      title: `Converge icon on ${slug}`,
    }),
  );
  write(
    lockupSource,
    backgroundLockupSvg({
      background,
      body,
      accent,
      title: `Converge lockup on ${slug}`,
    }),
  );
  renderPng(iconSource, join(root, "03-backgrounds", `converge-icon-on-${slug}.png`));
  renderPng(lockupSource, join(root, "03-backgrounds", `converge-lockup-on-${slug}.png`));
}

const appSources = [
  [
    "converge-app-icon-factory-black-1024",
    appIconSvg({
      background: colors.black,
      body: colors.ivory,
      accent: colors.gold,
      title: "Converge app icon on factory black",
    }),
  ],
  [
    "converge-app-icon-proof-ivory-1024",
    appIconSvg({
      background: colors.ivory,
      body: colors.black,
      accent: colors.gold,
      title: "Converge app icon on proof ivory",
    }),
  ],
  [
    "converge-app-icon-forge-gold-1024",
    appIconSvg({
      background: colors.gold,
      body: colors.black,
      accent: colors.ivory,
      title: "Converge app icon on forge gold",
    }),
  ],
];
for (const [name, body] of appSources) {
  const source = join(root, "00-source", "generated", `${name}.svg`);
  write(source, body);
  renderPng(source, join(root, "04-digital", "app-icons", `${name}.png`));
}

const darkAppSource = join(
  root,
  "00-source",
  "generated",
  "converge-app-icon-factory-black-1024.svg",
);
renderPng(darkAppSource, join(root, "04-digital", "app-icons", "android-chrome-192x192.png"), "192x192");
renderPng(darkAppSource, join(root, "04-digital", "app-icons", "android-chrome-512x512.png"), "512x512");
renderPng(darkAppSource, join(root, "04-digital", "app-icons", "apple-touch-icon.png"), "180x180");

const maskableSource = join(root, "00-source", "generated", "converge-maskable.svg");
write(
  maskableSource,
  appIconSvg({
    background: colors.black,
    body: colors.ivory,
    accent: colors.gold,
    maskable: true,
    title: "Converge maskable PWA icon",
  }),
);
renderPng(maskableSource, join(root, "04-digital", "app-icons", "pwa-maskable-512x512.png"), "512x512");

const faviconDarkSource = darkAppSource;
const faviconLightSource = join(
  root,
  "00-source",
  "generated",
  "converge-app-icon-proof-ivory-1024.svg",
);
for (const size of [16, 32, 48, 64, 96]) {
  renderPng(
    faviconDarkSource,
    join(root, "04-digital", "favicon", `converge-favicon-dark-${size}x${size}.png`),
    `${size}x${size}`,
  );
  renderPng(
    faviconLightSource,
    join(root, "04-digital", "favicon", `converge-favicon-light-${size}x${size}.png`),
    `${size}x${size}`,
  );
}
execFileSync(
  "magick",
  [
    faviconDarkSource,
    "-define",
    "icon:auto-resize=256,128,96,64,48,32,16",
    join(root, "04-digital", "favicon", "favicon.ico"),
  ],
  { stdio: "inherit" },
);
execFileSync(
  "magick",
  [
    faviconLightSource,
    "-define",
    "icon:auto-resize=256,128,96,64,48,32,16",
    join(root, "04-digital", "favicon", "converge-favicon-light.ico"),
  ],
  { stdio: "inherit" },
);

for (const [name, background, body, accent] of [
  ["converge-avatar-factory-black-1024", colors.black, colors.ivory, colors.gold],
  ["converge-avatar-proof-ivory-1024", colors.ivory, colors.black, colors.gold],
  ["converge-avatar-forge-gold-1024", colors.gold, colors.black, colors.ivory],
]) {
  const source = join(root, "00-source", "generated", `${name}.svg`);
  write(source, appIconSvg({ background, body, accent, title: name }));
  renderPng(source, join(root, "04-digital", "social", `${name}.png`));
}

const socialAssets = [
  [
    "converge-og-factory-black-1200x630",
    1200,
    630,
    colors.black,
    colors.ivory,
    colors.gold,
    false,
  ],
  [
    "converge-og-proof-ivory-1200x630",
    1200,
    630,
    colors.ivory,
    colors.black,
    colors.gold,
    false,
  ],
  [
    "converge-linkedin-cover-1584x396",
    1584,
    396,
    colors.black,
    colors.ivory,
    colors.gold,
    true,
  ],
  [
    "converge-x-cover-1500x500",
    1500,
    500,
    colors.black,
    colors.ivory,
    colors.gold,
    true,
  ],
  [
    "converge-github-social-preview-1280x640",
    1280,
    640,
    colors.black,
    colors.ivory,
    colors.gold,
    false,
  ],
];
for (const [name, width, height, background, body, accent, compact] of socialAssets) {
  const source = join(root, "00-source", "generated", `${name}.svg`);
  write(
    source,
    socialSvg({
      width,
      height,
      background,
      body,
      accent,
      compact,
      title: name,
    }),
  );
  renderPng(source, join(root, "04-digital", "social", `${name}.png`));
}

for (const size of [64, 128, 256, 512, 1024]) {
  for (const tone of ["dark", "light"]) {
    const source = join(primaryDir, `converge-icon-color-${tone}.svg`);
    renderPng(
      source,
      join(root, "05-web", "png", `converge-icon-color-${tone}-${size}.png`),
      `${size}x${size}`,
    );
  }
}
for (const width of [320, 640, 1280]) {
  for (const tone of ["dark", "light"]) {
    const source = join(primaryDir, `converge-lockup-color-${tone}.svg`);
    renderPng(
      source,
      join(root, "05-web", "png", `converge-lockup-color-${tone}-${width}w.png`),
      `${width}x`,
    );
  }
}

for (const name of [
  "converge-icon-color-dark",
  "converge-icon-color-light",
  "converge-lockup-color-dark",
  "converge-lockup-color-light",
  "converge-icon-black",
  "converge-icon-white",
  "converge-lockup-black",
  "converge-lockup-white",
]) {
  renderWebp(
    join(svgDir, `${name}.svg`),
    join(root, "05-web", "webp", `${name}.webp`),
  );
}

const overviewSource = join(root, "06-guidelines", "converge-brand-overview.svg");
write(overviewSource, overviewSvg());
renderPng(overviewSource, join(root, "06-guidelines", "converge-brand-overview.png"));

const walk = (dir) => {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const relativePath = relative(root, path);
    if (relativePath === "MANIFEST.sha256" || relativePath.endsWith(".zip")) continue;
    if (statSync(path).isDirectory()) results.push(...walk(path));
    else results.push(path);
  }
  return results;
};

const manifest = walk(root)
  .sort()
  .map((path) => {
    const digest = createHash("sha256").update(readFileSync(path)).digest("hex");
    return `${digest}  ${relative(root, path)}`;
  })
  .join("\n");
write(join(root, "MANIFEST.sha256"), `${manifest}\n`);

console.log(`Built Converge brand kit at ${root}`);
