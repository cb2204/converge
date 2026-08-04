#!/usr/bin/env node
/**
 * Converge Owner's Handbook v2 — full curriculum + fixed layout + SVG diagrams.
 * Output: owner-handbook.html (scroll-snap + html-to-pdf capture-ready)
 */
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const out = join(__dirname, "owner-handbook.html");

let n = 0;
const slides = [];

function esc(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function slide(opts, body) {
  n += 1;
  const num = String(n).padStart(2, "0");
  const meta = opts.meta || "Owner's handbook";
  const cover = !!opts.cover;
  slides.push(`
<section class="slide${cover ? " cover" : ""}" data-page="${num}" id="s${num}">
  <div class="page-bg" aria-hidden="true"><div class="grid"></div><div class="glow glow-gold"></div></div>
  <div class="inner">
    ${cover ? "" : `<div class="chrome-top"><img class="mark" src="converge-lockup-color-light.svg" alt="Converge"><div class="meta">${esc(meta)}</div></div>`}
    ${body}
    <div class="chrome-bottom">
      <div class="proof">${opts.proof || 'Done is proven.'}</div>
      <div class="page-num">${num} <span>/ TOTAL</span></div>
    </div>
  </div>
</section>`);
}

/** Steps: wrap body so CSS grid never traps <p> in the 28px number column */
function steps(items) {
  return `<div class="steps">${items
    .map(
      ([title, body]) =>
        `<div class="step"><div class="step-body"><strong>${title}</strong><p>${body}</p></div></div>`
    )
    .join("")}</div>`;
}

function table(headers, rows, compact = true) {
  const th = headers.map((h) => `<th>${h}</th>`).join("");
  const tr = rows
    .map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join("")}</tr>`)
    .join("");
  return `<div class="tablebox${compact ? " compact" : ""}"><table><thead><tr>${th}</tr></thead><tbody>${tr}</tbody></table></div>`;
}

function cards(items, cols = 3) {
  const cls = cols === 2 ? "grid-2" : cols === 4 ? "grid-4" : "grid-3";
  return `<div class="${cls} mt">${items
    .map(
      ([edge, label, h, p]) =>
        `<article class="card${edge ? " " + edge : ""}"><div class="label">${label}</div><h3>${h}</h3><p>${p}</p></article>`
    )
    .join("")}</div>`;
}

function callout(lead, rest) {
  return `<div class="callout mt"><p>${lead} <span>${rest}</span></p></div>`;
}

function chk(items) {
  return `<ul class="chk">${items.map((i) => `<li>${i}</li>`).join("")}</ul>`;
}

/* ── SVG diagrams (inline, brand colors, capture-safe) ── */

const SVG_SPINE = `
<svg class="diagram" viewBox="0 0 1100 160" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Nine pass spine">
  <defs>
    <linearGradient id="gBarrier" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#F3B64C" stop-opacity=".25"/><stop offset="100%" stop-color="#111720" stop-opacity="0"/></linearGradient>
  </defs>
  ${[
    [0, "0", "Capture", "opt"],
    [1, "1", "Intent", "spec"],
    [2, "2", "Structure", "ADRs"],
    [3, "3", "Decompose", "plans"],
    [4, "4", "Consensus", "BARRIER"],
    [5, "5", "Tasking", "seal"],
    [6, "6", "Register", "opt"],
    [7, "7", "Bind", "contract"],
    [8, "8", "Loop", "settle"],
  ]
    .map(([i, num, name, tag]) => {
      const x = 20 + i * 120;
      const barrier = i === 4;
      const corner = i === 5;
      const stroke = barrier ? "#F3B64C" : corner ? "#73E2C3" : "rgba(141,153,166,.35)";
      const fill = barrier ? "url(#gBarrier)" : "#111720";
      return `
    <rect x="${x}" y="24" width="108" height="112" rx="12" fill="${fill}" stroke="${stroke}" stroke-width="${barrier ? 1.8 : 1}"/>
    <text x="${x + 54}" y="52" text-anchor="middle" fill="#F3B64C" font-family="Menlo,monospace" font-size="13" font-weight="700">${num}</text>
    <text x="${x + 54}" y="78" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="12" font-weight="600">${name}</text>
    <text x="${x + 54}" y="100" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="9">${tag}</text>
    ${i < 8 ? `<path d="M${x + 112} 80 L${x + 118} 80" stroke="#F3B64C" stroke-width="1.5" opacity=".5"/>` : ""}`;
    })
    .join("")}
</svg>`;

const SVG_LAYERS = `
<svg class="diagram diagram-md" viewBox="0 0 1100 200" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Skill chat CLI layers">
  <rect x="20" y="30" width="240" height="140" rx="14" fill="#111720" stroke="#F3B64C" stroke-width="1.6"/>
  <text x="140" y="62" text-anchor="middle" fill="#F3B64C" font-family="Menlo,monospace" font-size="10" letter-spacing="1.5">YOU · OWNER</text>
  <text x="140" y="95" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="16" font-weight="600">Intent &amp; judgment</text>
  <text x="140" y="120" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">Sign · barrier · stamps</text>
  <text x="140" y="140" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">Read tokens, not vibes</text>

  <path d="M275 100 L305 100" stroke="#F3B64C" stroke-width="2"/><polygon points="305,96 318,100 305,104" fill="#F3B64C"/>

  <rect x="330" y="30" width="240" height="140" rx="14" fill="#111720" stroke="rgba(141,153,166,.35)"/>
  <text x="450" y="62" text-anchor="middle" fill="#F3B64C" font-family="Menlo,monospace" font-size="10" letter-spacing="1.5">CHAT AGENT</text>
  <text x="450" y="95" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="16" font-weight="600">Execution surface</text>
  <text x="450" y="120" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">SKILL.md · grill · write cvg/</text>
  <text x="450" y="140" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">Invoke gates when steered</text>

  <path d="M585 100 L615 100" stroke="#F3B64C" stroke-width="2"/><polygon points="615,96 628,100 615,104" fill="#F3B64C"/>

  <rect x="640" y="30" width="240" height="140" rx="14" fill="#111720" stroke="rgba(141,153,166,.35)"/>
  <text x="760" y="62" text-anchor="middle" fill="#F3B64C" font-family="Menlo,monospace" font-size="10" letter-spacing="1.5">CVG REFEREE</text>
  <text x="760" y="95" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="16" font-weight="600">Deterministic gates</text>
  <text x="760" y="120" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">No API keys · no LLM</text>
  <text x="760" y="140" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="11">Greppable tokens only</text>

  <path d="M895 100 L925 100" stroke="#73E2C3" stroke-width="2"/><polygon points="925,96 938,100 925,104" fill="#73E2C3"/>
  <rect x="950" y="50" width="130" height="100" rx="12" fill="#0f2a24" stroke="#73E2C3"/>
  <text x="1015" y="95" text-anchor="middle" fill="#73E2C3" font-family="Menlo,monospace" font-size="11">DISK</text>
  <text x="1015" y="118" text-anchor="middle" fill="#8D99A6" font-family="Inter,sans-serif" font-size="10">cvg/ truth</text>
</svg>`;

const SVG_ARCHITECTURE = `
<svg class="diagram diagram-md" viewBox="0 0 1100 280" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="System architecture planes">
  <rect x="400" y="8" width="300" height="44" rx="10" fill="#443614" stroke="#F3B64C"/>
  <text x="550" y="36" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="13" font-weight="600">HUMAN AUTHORITY · goals · risk · approvals</text>
  <path d="M550 52 L550 68" stroke="#F3B64C" stroke-width="1.5"/>
  <rect x="80" y="72" width="200" height="56" rx="10" fill="#17324a" stroke="#5b9bd5"/>
  <text x="180" y="98" text-anchor="middle" fill="#e8f2fb" font-family="Inter,sans-serif" font-size="12" font-weight="600">METHOD</text>
  <text x="180" y="116" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="10">Passes 0–8</text>
  <rect x="320" y="72" width="200" height="56" rx="10" fill="#17324a" stroke="#5b9bd5"/>
  <text x="420" y="98" text-anchor="middle" fill="#e8f2fb" font-family="Inter,sans-serif" font-size="12" font-weight="600">SKILLS</text>
  <text x="420" y="116" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="10">role procedures</text>
  <rect x="560" y="72" width="200" height="56" rx="10" fill="#17324a" stroke="#5b9bd5"/>
  <text x="660" y="98" text-anchor="middle" fill="#e8f2fb" font-family="Inter,sans-serif" font-size="12" font-weight="600">STATE · cvg/</text>
  <text x="660" y="116" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="10">canonical artifacts</text>
  <rect x="800" y="72" width="200" height="56" rx="10" fill="#443614" stroke="#F3B64C"/>
  <text x="900" y="98" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="12" font-weight="600">CONTROL · cvg</text>
  <text x="900" y="116" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="10">gates · bindings</text>
  <path d="M180 128 L180 150 L420 150 L420 128" stroke="rgba(141,153,166,.4)" fill="none"/>
  <path d="M660 128 L660 150 L900 150 L900 128" stroke="rgba(141,153,166,.4)" fill="none"/>
  <path d="M550 150 L550 168" stroke="#F3B64C" stroke-width="1.5"/>
  <rect x="300" y="172" width="500" height="48" rx="10" fill="#153c2c" stroke="#73E2C3"/>
  <text x="550" y="201" text-anchor="middle" fill="#e7fff3" font-family="Inter,sans-serif" font-size="13" font-weight="600">RUNTIME · harness · workers · tools → EVIDENCE · evals · stamps · receipts</text>
  <path d="M550 220 L550 238" stroke="#73E2C3" stroke-width="1.5"/>
  <rect x="360" y="242" width="380" height="32" rx="8" fill="#111720" stroke="rgba(141,153,166,.35)"/>
  <text x="550" y="263" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="10">feedback loop → human authority</text>
</svg>`;

function svgVerticalPass(title, nodes) {
  // nodes: [{label, sub, tone?}] tone: gold|mint|coral|default
  const h = 36;
  const gap = 10;
  const top = 8;
  const height = top + nodes.length * (h + gap) + 8;
  const boxes = nodes
    .map((node, i) => {
      const y = top + i * (h + gap);
      const stroke =
        node.tone === "gold"
          ? "#F3B64C"
          : node.tone === "mint"
            ? "#73E2C3"
            : node.tone === "coral"
              ? "#FF6B64"
              : "rgba(141,153,166,.35)";
      const arrow =
        i < nodes.length - 1
          ? `<path d="M200 ${y + h} L200 ${y + h + gap}" stroke="#F3B64C" stroke-width="1.2" opacity=".6"/><polygon points="196,${y + h + gap - 4} 200,${y + h + gap} 204,${y + h + gap - 4}" fill="#F3B64C" opacity=".6"/>`
          : "";
      return `
      <rect x="40" y="${y}" width="320" height="${h}" rx="8" fill="#111720" stroke="${stroke}"/>
      <text x="56" y="${y + 16}" fill="#F3B64C" font-family="Menlo,monospace" font-size="9">${esc(node.label)}</text>
      <text x="56" y="${y + 28}" fill="#8D99A6" font-family="Inter,sans-serif" font-size="10">${esc(node.sub || "")}</text>
      ${arrow}`;
    })
    .join("");
  return `<svg class="diagram diagram-v" viewBox="0 0 400 ${height}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="${esc(title)}">${boxes}</svg>`;
}

const SVG_LOOP = `
<svg class="diagram diagram-md" viewBox="0 0 1100 220" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Pass 8 loop">
  <rect x="40" y="70" width="160" height="70" rx="12" fill="#17324a" stroke="#5b9bd5"/>
  <text x="120" y="100" text-anchor="middle" fill="#e8f2fb" font-size="13" font-weight="600" font-family="Inter,sans-serif">BIND + READ</text>
  <text x="120" y="120" text-anchor="middle" fill="#8D99A6" font-size="10" font-family="Menlo,monospace">profile · sealed spec</text>
  <path d="M210 105 L240 105" stroke="#F3B64C" stroke-width="2"/><polygon points="240,101 252,105 240,109" fill="#F3B64C"/>
  <rect x="260" y="70" width="160" height="70" rx="12" fill="#443614" stroke="#F3B64C"/>
  <text x="340" y="100" text-anchor="middle" fill="#F5F2EA" font-size="13" font-weight="600" font-family="Inter,sans-serif">ATTEMPT</text>
  <text x="340" y="120" text-anchor="middle" fill="#8D99A6" font-size="10" font-family="Menlo,monospace">fresh engine process</text>
  <path d="M430 105 L460 105" stroke="#F3B64C" stroke-width="2"/><polygon points="460,101 472,105 460,109" fill="#F3B64C"/>
  <rect x="480" y="70" width="160" height="70" rx="12" fill="#443614" stroke="#F3B64C"/>
  <text x="560" y="100" text-anchor="middle" fill="#F5F2EA" font-size="13" font-weight="600" font-family="Inter,sans-serif">EVAL</text>
  <text x="560" y="120" text-anchor="middle" fill="#8D99A6" font-size="10" font-family="Menlo,monospace">task's own evals</text>
  <path d="M560 140 L560 165 L340 165 L340 140" stroke="#FF6B64" stroke-width="1.5" fill="none" stroke-dasharray="4 3"/>
  <text x="450" y="182" text-anchor="middle" fill="#FF6B64" font-size="10" font-family="Menlo,monospace">RED + budget → retry</text>
  <path d="M650 105 L680 105" stroke="#73E2C3" stroke-width="2"/><polygon points="680,101 692,105 680,109" fill="#73E2C3"/>
  <rect x="700" y="40" width="180" height="55" rx="12" fill="#153c2c" stroke="#73E2C3"/>
  <text x="790" y="65" text-anchor="middle" fill="#e7fff3" font-size="12" font-weight="600" font-family="Inter,sans-serif">SETTLED / LOCAL</text>
  <text x="790" y="82" text-anchor="middle" fill="#8D99A6" font-size="10" font-family="Menlo,monospace">path guard · receipt last</text>
  <rect x="700" y="115" width="180" height="55" rx="12" fill="#471f1d" stroke="#FF6B64"/>
  <text x="790" y="140" text-anchor="middle" fill="#ffe9e6" font-size="12" font-weight="600" font-family="Inter,sans-serif">BLOCKED · STALLED</text>
  <text x="790" y="157" text-anchor="middle" fill="#8D99A6" font-size="10" font-family="Menlo,monospace">EXHAUSTED · ERROR</text>
  <path d="M640 90 L700 65" stroke="#73E2C3" stroke-width="1.2" opacity=".7"/>
  <path d="M640 120 L700 140" stroke="#FF6B64" stroke-width="1.2" opacity=".7"/>
</svg>`;

const SVG_WORKSPACE = `
<svg class="diagram diagram-md" viewBox="0 0 1100 240" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Workspace folders">
  ${[
    [30, "docs/brd", "0"],
    [165, "tech-spec", "1"],
    [300, "adrs", "2"],
    [435, "swimlanes", "3–4"],
    [570, "tasks", "5"],
    [705, "execution", "7"],
    [840, "loop+", "8"],
  ]
    .map(
      ([x, name, pass]) => `
    <rect x="${x}" y="50" width="120" height="130" rx="12" fill="#111720" stroke="rgba(141,153,166,.35)"/>
    <text x="${x + 60}" y="90" text-anchor="middle" fill="#F3B64C" font-family="Menlo,monospace" font-size="11">pass ${pass}</text>
    <text x="${x + 60}" y="120" text-anchor="middle" fill="#F5F2EA" font-family="Inter,sans-serif" font-size="13" font-weight="600">${name}</text>
    <text x="${x + 60}" y="145" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="9">cvg/</text>`
    )
    .join("")}
  <text x="550" y="220" text-anchor="middle" fill="#8D99A6" font-family="Menlo,monospace" font-size="11">+ .cvg/gate.yaml · brain/ · receipts/ · lessons/</text>
</svg>`;

/* ═══════════════════════════════════════════════════════════
   CONTENT
   ═══════════════════════════════════════════════════════════ */

// COVER
slide({ cover: true, proof: "Proof line · <em>Done is proven</em>" }, `
  <img class="cover-icon" src="converge-icon-color-light.svg" width="92" height="92" alt="">
  <p class="eyebrow">Owner's handbook · complete edition · v2</p>
  <h1>Converge</h1>
  <p class="subtitle">From intent to evidence · every pass · every relationship</p>
  <p class="tagline">Compile intent into<br><em>shipped software.</em></p>
  <p class="proof-line">Done is proven.</p>
  <div class="cover-meta">
    <span><b>Identity</b> · Settlement Fold</span>
    <span><b>Audience</b> · Owners &amp; operators</span>
    <span><b>Spine</b> · Passes 0–8 + operating layer</span>
    <span><b>Depth</b> · skill · chat · CLI · gates</span>
  </div>
`);

// ORIENTATION
slide({ meta: "Orientation" }, `
  <p class="eyebrow">00 · How to use this book</p>
  <h2>You are the owner. Agents write. Gates prove.</h2>
  <p class="lead">This handbook transfers the full Converge curriculum: every pass, the relationships between <strong>skill · chat interface · cvg CLI</strong>, architecture diagrams, procedures, and owner checklists.</p>
  ${cards([
    ["gold-edge", "Rule of thumb", "Four truths", "Skill writes · CLI scores · folders remember · <strong>you decide</strong>."],
    ["", "How to read", "Tokens over vibes", "A pass is done when the greppable gate token says so — never when work “feels finished.”"],
    ["mint-edge", "Structure", "Chapters", "Thesis → system → operating layer → each pass vertical → worked example → recovery."],
  ])}
  ${callout("Converged ≠ “feels done.”", "Converged = gate token green + your required sign-offs.")}
`);

// THESIS
slide({ meta: "Thesis" }, `
  <p class="eyebrow">01 · Thesis</p>
  <h2>Autonomy needs a<br><span class="gold">method spine.</span></h2>
  <p class="lead"><strong>Converge compiles intent into software</strong> through nine gated passes. Agents build. Machines check. Completion is a state-machine invariant — not an agent’s claim.</p>
  <div class="kpis mt">
    <div class="kpi"><b class="gold">9</b><span>Spine passes</span></div>
    <div class="kpi"><b>12</b><span>Skills (9+3 util)</span></div>
    <div class="kpi"><b class="mint">1</b><span>Referee CLI</span></div>
    <div class="kpi"><b>0</b><span>Keys in cvg</span></div>
  </div>
  ${cards([
    ["gold-edge", "Before", "Fragmented intent", "Chat, tickets, unspoken assumptions. Success is narrated after the fact."],
    ["", "Through", "Versioned altitude", "Each pass emits a durable artifact with entry/exit criteria and an executable gate."],
    ["mint-edge", "After", "Named terminal truth", "Work ends in greppable states: SETTLED, BLOCKED, EXHAUSTED — never “I got tired.”"],
  ])}
`);

// FIVE NON-NEGOTIABLES — FIXED STEPS
slide({ meta: "Non-negotiables" }, `
  <p class="eyebrow">01 · Why it's different</p>
  <h2>Five non‑negotiables</h2>
  ${steps([
    ["The eval decides done.", "A task cannot settle until its evals exit 0. The maximal stub attack (all specs faked) lands all RED."],
    ["The referee is never a player.", "<span class=\"mono\">cvg</span> holds no API keys and calls no models. Engine CLIs authenticate themselves; the referee only frames, dispatches, and gates."],
    ["Cross-family when it matters.", "Pass 4 adversary + Pass 8 tier-2 verify send work to a different model family, prompted to refute — including holdouts the builder never saw."],
    ["A loop with brakes.", "Three-axis budgets (iterations · wall-clock · tokens) + stagnation. Only SETTLED, LOCAL_SETTLED, and NO_OP exit zero."],
    ["Evidence over memory.", "Position is derived from <span class=\"mono\">cvg/</span> folders. Sessions die; disks don’t. <span class=\"mono\">cvg next</span> never trusts chat scrollback."],
  ])}
`);

// ARCHITECTURE
slide({ meta: "Architecture" }, `
  <p class="eyebrow">02 · System architecture</p>
  <h2>Four planes + runtime</h2>
  <p class="lead">Human authority enters; machine evidence returns. Each plane has a different source of truth and failure mode.</p>
  <div class="diagram-wrap mt">${SVG_ARCHITECTURE}</div>
  ${callout("Fail-closed hierarchy.", "Missing authority, failed checks, invalid seals, or unresolved objections block the unattended path. Waivers stay visible and owner-owned.")}
`);

// THREE LAYERS
slide({ meta: "Three layers" }, `
  <p class="eyebrow">02 · Skill · chat · CLI</p>
  <h2>Three layers. One truth.</h2>
  <p class="lead">One play, three roles. They never swap jobs. Disk evidence survives the session — chat does not.</p>
  <div class="diagram-wrap mt">${SVG_LAYERS}</div>
  ${table(
    ["Layer", "Does", "Does not"],
    [
      ["<strong>Skill</strong>", "Teaches how to interview, draft, gate", "Run itself; hold credentials"],
      ["<strong>Chat agent</strong>", "Does the work; writes <span class=\"mono\">cvg/</span>; runs gates", "Own business truth; sign for you"],
      ["<strong>cvg CLI</strong>", "Finds files; runs gate scripts; prints tokens", "Write product code; call models"],
      ["<strong>You</strong>", "Decisions, canonical, barrier, stamps", "Memorize every flag (agent can drive)"],
    ]
  )}
`);

// WORKSPACE
slide({ meta: "Workspace" }, `
  <p class="eyebrow">02 · Control plane</p>
  <h2>The <span class="mono">cvg/</span> workspace</h2>
  <p class="lead">Everything Converge “remembers” is folders on disk. <span class="mono">cvg/</span> is the workspace — not always the git root.</p>
  <div class="diagram-wrap mt">${SVG_WORKSPACE}</div>
  ${table(
    ["Path", "Pass", "Content"],
    [
      ["<span class=\"mono\">.cvg/gate.yaml</span>", "init", "Write fence a Task-Spec cannot widen"],
      ["<span class=\"mono\">cvg/docs/brd/</span>", "0", "BRD or no-go"],
      ["<span class=\"mono\">cvg/docs/tech-spec/</span>", "1", "Falsifiable requirements"],
      ["<span class=\"mono\">cvg/docs/adrs/</span>", "2", "Terrain ADRs + CONTEXT.md"],
      ["<span class=\"mono\">cvg/swimlanes/</span>", "3–4", "Plans + objection log"],
      ["<span class=\"mono\">cvg/tasks/</span>", "5", "Sealed Task-Specs"],
      ["<span class=\"mono\">cvg/execution/</span>", "7", "Profiles + adapters"],
      ["<span class=\"mono\">cvg/loop/ · receipts/</span>", "8", "Checkpoints + settlement"],
    ]
  )}
`);

// SETUP
slide({ meta: "Setup" }, `
  <p class="eyebrow">02 · First day</p>
  <h2>Stand up the factory</h2>
  ${steps([
    ["cvg init", "Creates workspace + <span class=\"mono\">.cvg/gate.yaml</span>. Idempotent · <span class=\"mono\">CVG_INIT=OK|UNCHANGED</span>."],
    ["cvg setup signing", "Repo-private HMAC key so Task-Specs can be sealed. Never commit the key. Mode 0600 under Git-private state."],
    ["cvg setup", "Readiness board + exact next step · <span class=\"mono\">SETUP=READY|INCOMPLETE</span>."],
    ["Optional integrations", "<span class=\"mono\">setup tracker · setup key · setup repo · setup harness · doctor</span>. Secrets stay out of <span class=\"mono\">.cvg/</span> — only choices are recorded."],
  ])}
  ${callout("Two roots.", "<span class=\"mono\">CVG_HOME</span> = installed Converge package. <span class=\"mono\">CVG_PROJECT_ROOT</span> = consuming project. Workspace may sit below the git root.")}
`);

// LANES
slide({ meta: "Lanes" }, `
  <p class="eyebrow">02 · Ceremony router</p>
  <h2>Lanes route. They never waive.</h2>
  <p class="lead"><span class="mono">cvg lane "…"</span> picks how much of the spine a change earns. Same final bar everywhere: green eval + path guard.</p>
  ${cards(
    [
      ["", "FAST", "5 → 7 → 8", "Typo, rename, one-file fix. Small &amp; reversible only."],
      ["gold-edge", "NORMAL", "1 · 2 · 5 · 7 · 8", "Most features. Intent + structure without full design theatre."],
      ["", "FULL", "0 → 8", "New idea, new seam, backbone, architecture."],
    ],
    3
  )}
  ${table(
    ["Hard floor", "Effect"],
    [
      ["auth · money · migrations · secrets · public API", "<strong>Never FAST</strong>"],
      ["irreversible / production delete · purge · rotate", "<strong>Never FAST</strong>"],
      ["new service · new seam · greenfield · architecture", "<strong>Forces FULL</strong>"],
      ["unsigned eval / no sealed spec", "<strong>No lane dispatches</strong>"],
      [">5 files tightens FAST→NORMAL · >15 → FULL pressure", "File counts only ever <strong>tighten</strong>"],
    ]
  )}
`);

// CONDUCTOR
slide({ meta: "Conductor" }, `
  <p class="eyebrow">02 · evidence-to-next-pass</p>
  <h2><span class="mono">cvg next</span> — the descent conductor</h2>
  <p class="lead">Derives where the descent stands from workspace evidence. No state file. No memory. No drift between sessions.</p>
  ${cards([
    ["gold-edge", "next", "Where am I?", "Evidence board · <span class=\"mono\">NEXT_PASS=N|DONE</span> · skill + <span class=\"mono\">pass-prompt.md</span> path · closing gate"],
    ["", "pre N", "May pass N start?", "Fail-closed door. Prior lane passes must leave artifacts. <span class=\"mono\">PASS_PRE=OK|MISSING</span>"],
    ["mint-edge", "post N", "Did N land?", "Folder filled? <span class=\"mono\">PASS_POST=OK|INCOMPLETE</span> — then still run the authoritative <span class=\"mono\">cvg</span> gate."],
  ])}
  ${callout("Critical rule.", "<strong>Evidence presence is not a verdict.</strong> A BRD file existing ≠ <span class=\"mono\">CHECK_BRD=PASS</span>. Conductor sequences; gates decide. Pre can block forward; it can never grant a pass.")}
`);

// LESSON
slide({ meta: "Teaching" }, `
  <p class="eyebrow">02 · pass-to-lesson</p>
  <h2>Own the understanding</h2>
  <p class="lead">Optional after any pass. Never blocks the descent. Prevents “the autonomous did it” as an answer to “why is it shaped this way?”</p>
  ${cards([
    ["gold-edge", "Four-part treatment", "Every component", "What it is · why shaped · decision encoded · <strong>what breaks downstream without it</strong>."],
    ["", "Durable file", "cvg/docs/lessons/", "Survives chat. Onboarding + pre-read for client calls."],
    ["mint-edge", "Gate", "cvg lesson", "Seven sections · decisions table · 3–5 quiz Qs · <span class=\"mono\">CHECK_LESSON=PASS</span>. Optional <span class=\"mono\">--immutable</span>."],
  ])}
  ${callout("Explain, never reopen.", "Disagreements become change requests on the owning pass — not silent edits to gated artifacts.")}
`);

// SPINE OVERVIEW
slide({ meta: "The spine" }, `
  <p class="eyebrow">03 · Pass map</p>
  <h2>Nine gates. One barrier.</h2>
  <p class="lead">Design half (0–4) makes intent precise. <strong>Pass 4 is the last human design sign-off.</strong> Build half (5–8) is machine-led proof.</p>
  <div class="diagram-wrap mt">${SVG_SPINE}</div>
  ${cards(
    [
      ["gold-edge", "Phase 1 · Design", "Human-led 0–4", "BRD → requirements → ADRs → plans → cross-family attack. You grill, approve, sign the barrier."],
      ["mint-edge", "Phase 2 · Build", "Machine-led 5–8", "Sealed Task-Specs → optional board → bind → attempt/verify/settle under budgets."],
    ],
    2
  )}
`);

// CHEAT SHEET
slide({ meta: "Pass ↔ CLI map" }, `
  <p class="eyebrow">03 · Master cheat sheet</p>
  <h2>Pass · skill · CLI · token · evidence</h2>
  ${table(
    ["#", "Pass", "Skill", "CLI", "Token", "Evidence"],
    [
      ["0", "Capture", "idea-to-brd", "cvg capture", "CHECK_BRD", "docs/brd/"],
      ["1", "Intent", "brd-docs-to-tech-req", "cvg intent", "CHECK_TECH_SPEC", "docs/tech-spec/"],
      ["2", "Structure", "tech-req-to-adrs", "cvg structure", "CHECK_ADR", "docs/adrs/"],
      ["3", "Decompose", "reqs-to-swimlane-plans", "cvg decompose", "CHECK_PLAN", "swimlanes/"],
      ["4", "Consensus", "sketch-plans-adversarial-review", "cvg review", "CHECK_CONSENSUS", ".consensus/"],
      ["5", "Tasking", "task-spec", "cvg tasks *", "TIER=1", "tasks/"],
      ["6", "Register", "task-specs-to-issues", "cvg register", "CHECK_REGISTER", "tracker"],
      ["7", "Bind", "task-to-runtime-contract", "cvg bind", "CHECK_RUNTIME_CONTRACT", "execution/"],
      ["8", "Loop", "task-loop", "cvg loop", "TASK_LOOP", "loop/ · receipts/"],
    ]
  )}
`);

/* ── PASS 0 ── */
slide({ meta: "Pass 0 · Capture" }, `
  <p class="eyebrow">Pass 0 · idea-to-brd · optional</p>
  <h2>Capture — raw idea → BRD</h2>
  <p class="lead">Turn a founder thought into a <strong>brief in the owner’s voice</strong> — or a durable no-go. Never the tech-spec. Never architecture.</p>
  <div class="split mt">
    <div>
      ${svgVerticalPass("Pass 0 flow", [
        { label: "IN", sub: "Raw idea · voice note · whiteboard" },
        { label: "1 · Scope-check", sub: "One idea? Slice multi-headed" },
        { label: "2 · Grill", sub: "Frontier rounds + defaults" },
        { label: "2b · No-go?", sub: "Do-nothing tolerable → park", tone: "coral" },
        { label: "3 · Draft BRD", sub: "Owner voice · provenance tags" },
        { label: "4 · Gate", sub: "YOU set canonical", tone: "gold" },
        { label: "OUT", sub: "CHECK_BRD=PASS → Pass 1", tone: "mint" },
      ])}
    </div>
    <div>
      ${table(
        ["", "Contract"],
        [
          ["Skill", "idea-to-brd"],
          ["CLI", "<span class=\"mono\">cvg capture [--draft|--no-go]</span>"],
          ["Token", "<span class=\"mono\">CHECK_BRD=PASS|FAIL|DRAFT_OK|NOGO_OK</span>"],
          ["Skip when", "Client BRD already exists → enter Pass 1"],
          ["Altitude", "Problem only — no requirements, no stack"],
        ]
      )}
      ${callout("Anti-pattern.", "“Too small for a BRD” is forbidden. Small ideas hide the costliest assumptions. Half-page BRDs still gate.")}
    </div>
  </div>
`);

slide({ meta: "Pass 0 · Procedure" }, `
  <p class="eyebrow">Pass 0 · every step</p>
  <h2>Scope-check → grill → draft → gate</h2>
  ${steps([
    ["1 · Scope-check", "Is this one idea or four platforms? Flag decomposition first. Look up facts in the repo / <span class=\"mono\">cvg/docs/</span> — never burn questions on what files know."],
    ["2 · Grill · frontier rounds", "Design tree: pain · do-nothing · goal · scope · success · constraints · pre-mortem. Each round: numbered questions + recommended defaults. One reply answers the whole round (dictation-friendly)."],
    ["Numbers carry provenance", "Every number tagged <span class=\"mono\">(measured)</span> · <span class=\"mono\">(estimated)</span> · <span class=\"mono\">(guessed)</span>. A guess spawns an owned open question. Never invent “measured” under pressure."],
    ["2b · No-go exit", "If do-nothing is fine → <span class=\"mono\">cvg/docs/no-go/&lt;slug&gt;.md</span> (idea · date · owner · why · reopen condition) · <span class=\"mono\">cvg capture --no-go</span>. Cheapest kill in the whole descent."],
    ["3 · Draft", "<span class=\"mono\">cvg/docs/brd/&lt;slug&gt;.md</span> from template. Executive summary last (≤60 words). Sign-off present as <span class=\"mono\">_pending_</span> until you flip to canonical."],
    ["4 · Gate", "<span class=\"mono\">cvg capture --draft</span> while writing (never authorizes handoff). You set <strong>canonical + real ISO date</strong>. <span class=\"mono\">cvg capture</span> → <span class=\"mono\">CHECK_BRD=PASS</span>."],
  ])}
`);

slide({ meta: "Pass 0 · Owner" }, `
  <p class="eyebrow">Pass 0 · your role</p>
  <h2>Owner checklist · Capture</h2>
  <div class="grid-2 mt">
    <article class="card gold-edge"><div class="label">During grill</div>${chk([
      "Answer rounds in one block when possible",
      "Prefer honest <span class=\"mono\">(guessed)</span> over invented certainty",
      "Say “don’t build it” if do-nothing is fine",
      "Name one <strong>decider</strong> if many stakeholders",
    ])}</article>
    <article class="card mint-edge"><div class="label">To leave Pass 0</div>${chk([
      "Sounds like you, not a requirements doc",
      "Scope Out is real (not empty / “none”)",
      "Every open question has a named owner",
      "You set Sign-off to <strong>canonical</strong> + real date",
      "<span class=\"mono\">CHECK_BRD=PASS</span>",
    ])}</article>
  </div>
  ${callout("Forbidden altitude.", "No “system shall,” no stack decisions, no architecture. Park tech preferences as open questions for Pass 3.")}
`);

/* ── PASS 1 ── */
slide({ meta: "Pass 1 · Intent" }, `
  <p class="eyebrow">Pass 1 · brd-docs-to-tech-req</p>
  <h2>Intent — BRD → testable requirements</h2>
  <p class="lead">Answer: <strong>what are we building, and how will we know it works?</strong> Never how it is built. Gate is falsifiability, not completeness.</p>
  <div class="split mt">
    <div>
      ${svgVerticalPass("Pass 1 flow", [
        { label: "IN", sub: "Signed BRD (or client brief)" },
        { label: "1 · Understand", sub: "One-paragraph problem restatement" },
        { label: "1.5 · Prior art", sub: "Problem-level only — no schemas" },
        { label: "2 · Interrogate", sub: "2–3 high-leverage decisions" },
        { label: "Gap register", sub: "Blockers need substantive resolution", tone: "coral" },
        { label: "3 · Crystallize", sub: "R-n · current→target · entities" },
        { label: "OUT", sub: "CHECK_TECH_SPEC=PASS", tone: "mint" },
      ])}
    </div>
    <div>
      ${table(
        ["", "Contract"],
        [
          ["CLI", "<span class=\"mono\">cvg intent [--draft]</span>"],
          ["Token", "<span class=\"mono\">CHECK_TECH_SPEC=PASS|…</span>"],
          ["Out", "<span class=\"mono\">cvg/docs/tech-spec/</span>"],
          ["Boundary", "Pass 0 = stakeholder voice · Pass 1 = how-well"],
          ["Stack", "Forbidden — Pass 3 / ADR territory"],
        ]
      )}
      ${callout("Ambiguity left here.", "Is inherited by every later pass. A soft Pass 1 makes ADRs, plans, tasks, and evals soft.")}
    </div>
  </div>
`);

slide({ meta: "Pass 1 · Falsifiable" }, `
  <p class="eyebrow">Pass 1 · rewrite pattern</p>
  <h2>Vague → falsifiable</h2>
  <p class="lead">A requirement needs all three: <strong>measured quantity · threshold with unit · input condition</strong>. Else → owned open assumption.</p>
  ${table(
    ["Vague (fails)", "Falsifiable (spirit of the gate)"],
    [
      ["“Dashboard should be fast”", "Revenue-by-month ≤ 3s p95 over 12 months of orders"],
      ["“Data reasonably fresh”", "Facts ≤ 15 min lag, ≥ 99% of the day"],
      ["“Accurate reports”", "Reconciled revenue matches ledger within $0.01 / closed day"],
      ["“Use DuckDB + dbt”", "Park as Pass 3 preference — not a requirement body line"],
    ]
  )}
  ${steps([
    ["Ids are forever", "<span class=\"mono\">R-n</span> requirements · <span class=\"mono\">W-n</span> wishes/wonts. Never renumber casually — ADRs and evals cite them."],
    ["Priorities", "Not everything is <span class=\"mono\">must</span>. Use should/could/wont. Deliberate exclusions are honest."],
    ["Blocker gaps", "Gate fails closed on missing/blank/sentinel resolutions (TBD, pending, open). Chase the named owner."],
  ])}
`);

/* ── PASS 2 ── */
slide({ meta: "Pass 2 · Structure" }, `
  <p class="eyebrow">Pass 2 · tech-req-to-adrs</p>
  <h2>Structure — ground the terrain</h2>
  <p class="lead">Lower altitude from <em>what to build</em> to <strong>what is true about the system we build on</strong>.</p>
  <div class="split mt">
    <div>
      ${svgVerticalPass("Pass 2 flow", [
        { label: "IN", sub: "Tech-spec + live repo" },
        { label: "1 · Name ground", sub: "Greenfield / brownfield · 0000" },
        { label: "2 · Ground", sub: "Run system · reconcile · schema" },
        { label: "3 · Record ADRs", sub: "Fact + evidence + consequence" },
        { label: "Glossary", sub: "CONTEXT.md as terms crystallize" },
        { label: "OUT", sub: "CHECK_ADR=OK · --final", tone: "mint" },
      ])}
    </div>
    <div>
      ${table(
        ["Grounding (keep)", "Design leak (reject)"],
        [
          ["Payments join orders on order_id", "Build fct_payments keyed on order_id"],
          ["Timestamps are TIMESTAMPTZ UTC", "Add date_day dimension truncating paid_at"],
          ["Revenue = paid payments only", "Implement revenue_paid as SQL sum"],
        ]
      )}
      ${callout("One-line test.", "Could this sentence have been true before anyone chose a solution? Yes → ADR. No → Pass 3.")}
    </div>
  </div>
`);

slide({ meta: "Pass 2 · Owner" }, `
  <p class="eyebrow">Pass 2 · lifecycle &amp; checklist</p>
  <h2>ADRs are immutable once accepted</h2>
  ${steps([
    ["Lifecycle", "<span class=\"mono\">proposed → accepted → deprecated | superseded</span>. Born proposed; accepted at review — never at scaffold time."],
    ["Supersede, don’t rewrite", "Reality changes → <span class=\"mono\">scaffold-adr.sh --supersede NNNN</span>. Bidirectional links. History stays honest."],
    ["Worthiness test", "Hard to reverse · stood on downstream · could have been otherwise. Else glossary line, not a numbered ADR."],
    ["CLI", "<span class=\"mono\">cvg structure</span> · <span class=\"mono\">cvg structure --final</span> (nothing left proposed) · <span class=\"mono\">CHECK_ADR=OK|FAIL|EMPTY</span>"],
  ])}
  <div class="grid-2 mt">
    <article class="card gold-edge"><div class="label">Accept</div>${chk(["Terrain named in 0000-context", "Brownfield was <strong>run</strong>, not summarized", "Every ADR cites evidence + re-proof command", "Terms in CONTEXT.md · <span class=\"mono\">spec_ref: R-n</span>"])}</article>
    <article class="card coral-edge"><div class="label">Reject</div>${chk(["Build/create/implement verbs in ADRs", "Design leaking into terrain", "Closing with records still proposed", "Fabricating schema you didn’t observe"])}</article>
  </div>
`);

/* ── PASS 3 ── */
slide({ meta: "Pass 3 · Decompose" }, `
  <p class="eyebrow">Pass 3 · reqs-to-swimlane-plans</p>
  <h2>Decompose — seam → swimlane → leg</h2>
  <p class="lead">Plan altitude only. <strong>No tasks. No implementation code.</strong> Plans are attacked next — soft spots are expected.</p>
  <div class="chain mt">
    <div class="chain-node">Seam<span>nameable interface</span></div>
    <div class="chain-arr">→</div>
    <div class="chain-node">Swimlane<span>one folder / plan</span></div>
    <div class="chain-arr">→</div>
    <div class="chain-node">Leg<span>one responsibility</span></div>
    <div class="chain-arr">→</div>
    <div class="chain-node gold">Task-Spec<span>Pass 5 · 1:N</span></div>
  </div>
  ${table(
    ["Hardening", "Rule", "Why you care"],
    [
      ["H1", "Exactly one steel-thread lane", "End-to-end path before fattening components"],
      ["H2", "risk= per lane; spike high first", "Fatal contracts surface early"],
      ["H3", "owner= stream/team", "Conway — wrong owner = coordination tax"],
      ["H4", "Seam evolution stated", "Additive vs breaking + coexistence"],
      ["H5", "Cycles broken explicitly", "Never a fuzzy two-way seam"],
    ]
  )}
  ${callout("Folder shape.", "<span class=\"mono\">cvg/swimlanes/&lt;seam&gt;/_lane.md</span> + <span class=\"mono\">leg-NN-&lt;tech&gt;.md</span>. Tech is a swappable label; stable key is <span class=\"mono\">swimlane-…-leg-NN</span>. CLI: <span class=\"mono\">cvg decompose → CHECK_PLAN=OK</span>.")}
`);

/* ── PASS 4 ── */
slide({ meta: "Pass 4 · Barrier" }, `
  <p class="eyebrow">Pass 4 · THE BARRIER · sketch-plans-adversarial-review</p>
  <h2>Consensus — last human design sign-off</h2>
  <p class="lead">A <strong>different model family</strong> attacks the plans. You FIX or ACCEPT every objection. Only you close the barrier.</p>
  <div class="split mt">
    <div>
      ${svgVerticalPass("Pass 4 flow", [
        { label: "Preflight", sub: "cvg doctor · cross-family ready" },
        { label: "1 · ATTACK", sub: "cvg review --adversary codex", tone: "gold" },
        { label: "2 · GROUND", sub: "Drift vs tech-spec + ADRs" },
        { label: "3 · SHARPEN", sub: "FIX or ACCEPT+owner each objection" },
        { label: "4 · BARRIER", sub: "YOU sign — agent must stop", tone: "gold" },
        { label: "5 · GATE", sub: "CHECK_CONSENSUS=OK", tone: "mint" },
      ])}
    </div>
    <div>
      ${table(
        ["Command", "Role"],
        [
          ["<span class=\"mono\">cvg doctor</span>", "≥2 engines · ≥1 cross-family"],
          ["<span class=\"mono\">cvg review --adversary E</span>", "Dispatch headless attack"],
          ["<span class=\"mono\">--timeout 900</span>", "Raise wall-clock for fat trees"],
          ["<span class=\"mono\">cvg review --check</span>", "Provenance re-hash + dispositions"],
        ]
      )}
      ${callout("Why here.", "Signing off before a different model tries to break the plan is signing off on an unexamined mandate. The machine would faithfully build the flaw.")}
    </div>
  </div>
`);

slide({ meta: "Pass 4 · Ops" }, `
  <p class="eyebrow">Pass 4 · procedures &amp; latency</p>
  <h2>Attack → dispose → sign · when review times out</h2>
  ${steps([
    ["ATTACK", "Playbook + plans → headless adversary. Default-to-refuted. Emits stamped objection log — never edits plans. Provenance (family + input hashes) stamped by the referee."],
    ["GROUND", "Where plans contradict tech-spec or ADRs. Cite both sides. No hand-waving."],
    ["SHARPEN", "Every objection: FIX (revise plan in place) or ACCEPT (risk + named owner + reason). Empirical fights → throwaway prototype as evidence."],
    ["BARRIER", "Present sharpened plans + dispositions. You sign explicitly. Agent must not start Pass 5 unsigned."],
    ["Timeout ops", "Default 300s is often short for 11 files. Use <span class=\"mono\">CVG_TIMEOUT_SECS=900</span> or <span class=\"mono\">--timeout 900</span>. Thin tree (steel-thread first). Avoid multi-adversary while debugging latency. Never use same-family Claude-on-Claude as a real barrier."],
  ])}
`);

/* ── PASS 5 ── */
slide({ meta: "Pass 5 · Tasking" }, `
  <p class="eyebrow">Pass 5 · cornerstone · task-spec</p>
  <h2>Tasking — evals first, then seal</h2>
  <p class="lead">Atomic, vendor-neutral, <strong>self-verifying</strong> units. No eval → not a task yet. After stamp, editing an eval breaks the HMAC seal.</p>
  ${cards([
    ["gold-edge", "PRE gate", "tasks gate --stamp", "Certifies the spec · <span class=\"mono\">VERDICT: DELEGATE</span> · <span class=\"mono\">TIER=1</span> · HMAC over eval bodies"],
    ["", "POST gate", "tasks accept", "Certifies the work after execution · seal recheck · blast radius"],
    ["mint-edge", "Frontier", "cvg ready", "status ready AND all depends_on done — never dispatch past the frontier"],
  ])}
  ${table(
    ["Effort", "Role", "Rule"],
    [
      ["XS · S · M · L", "Executable leaves", "Path budgets ≤1 / ≤2 / ≤3 / ≤5"],
      ["XL · XXL", "Decomposition nodes", "Must declare children: — never dispatched"],
      ["L leaves", "execution_backend: glm", "Sizing engine absorbs whole range"],
    ]
  )}
`);

slide({ meta: "Pass 5 · Procedure" }, `
  <p class="eyebrow">Pass 5 · per leg / unit</p>
  <h2>Author → validate → stamp → lint</h2>
  ${steps([
    ["Scaffold", "<span class=\"mono\">cvg tasks new &lt;slug&gt; &lt;effort&gt;</span> — honest sizing. XL/XXL must declare children."],
    ["Evals first", "Runnable bash asserting outcomes (state, files, query results) — not “the script ran.” Then goal, touches_paths, budgets, blast radius."],
    ["Holdout", "Judge-only criteria under <span class=\"mono\">## Holdout</span> — excluded from worker brief; reserved for tier-2 verify."],
    ["Validate + stamp", "<span class=\"mono\">cvg tasks validate</span> then you authorize <span class=\"mono\">cvg tasks gate --stamp</span>."],
    ["Lint backlog", "<span class=\"mono\">cvg lint</span> — cycles, write-surface overlaps. Optional <span class=\"mono\">cvg tasks dod</span> for behavior↔eval matrix."],
  ])}
  ${callout("Owner stamp policy.", "You authorize seals. After stamp: never edit evals without re-gate. Silent goalpost moves break every downstream check.")}
`);

/* ── PASS 6 ── */
slide({ meta: "Pass 6 · Register" }, `
  <p class="eyebrow">Pass 6 · opt-in · task-specs-to-issues</p>
  <h2>Register — specs ⇄ tracker board</h2>
  <p class="lead">One signed spec = one issue. <span class="mono">depends_on</span> → blocked-by. <strong>Repo specs remain canonical</strong>; the board is a shadow.</p>
  ${steps([
    ["Only signed_off: true", "Un-gated specs never hit the board. Skip and report the rest."],
    ["Idempotent upsert", "Re-runs update; never duplicate. Issue-side marker is the key; <span class=\"mono\">tracker_ref</span> is a convenience receipt only."],
    ["Exit Check travels", "Issue body carries the close condition. Only a green eval may mark done."],
    ["Gate", "<span class=\"mono\">cvg register --check</span> → 1:1 · DAG · no orphans · no un-gated leaks · <span class=\"mono\">CHECK_REGISTER=OK</span>"],
    ["Credentials", "Referee holds none. <span class=\"mono\">cvg setup key</span> → OS keychain. <span class=\"mono\">.cvg/</span> stores choices only."],
  ])}
  ${callout("Skip freely.", "Repo-local queue is valid. Loop reads either board or <span class=\"mono\">cvg/tasks/</span>.")}
`);

/* ── PASS 7 ── */
slide({ meta: "Pass 7 · Bind" }, `
  <p class="eyebrow">Pass 7 · task-to-runtime-contract</p>
  <h2>Bind — freeze the execution contract</h2>
  <p class="lead">One sealed leaf → enforceable profile. Fail closed if the host cannot honor a required control.</p>
  ${cards([
    ["gold-edge", "7A · Contract", "What RUNTIME enforces", "<span class=\"mono\">execution-profile.yaml</span> · path guards · capability envelope · adapter manifests"],
    ["", "7B · Brief", "What MODEL reads", "<span class=\"mono\">AGENTS.task.md</span> — identifiers only, not a novel of context"],
    ["mint-edge", "Fence", ".cvg/gate.yaml", "Repo write policy a Task-Spec cannot widen. <span class=\"mono\">cvg gate --path</span>"],
  ])}
  ${steps([
    ["Attest host", "<span class=\"mono\">cvg doctor runtime-contract</span> → OK | DEGRADED | FAIL — know what this machine can enforce"],
    ["Bind", "<span class=\"mono\">cvg bind --task &lt;spec&gt;</span> → <span class=\"mono\">CHECK_RUNTIME_CONTRACT=PASS</span>"],
    ["Recheck", "<span class=\"mono\">bind --check</span> is genuinely read-only — recomputes HMAC; never runs task evals"],
  ])}
`);

slide({ meta: "Pass 7 · Envelope" }, `
  <p class="eyebrow">Pass 7 · capability envelope</p>
  <h2>Authority that dies with the task</h2>
  ${cards([
    ["gold-edge", "Epoch", "task-id@spec-sha12", "Bound to one signed revision. Epoch change revokes authority."],
    ["", "Scope", "fs.write = spec paths", "Never wider than Task-Spec. Fence cannot be widened by the task."],
    ["mint-edge", "Closure", "settle · block · exhaust", "No lingering session permissions after the task ends."],
  ])}
  ${table(
    ["Assurance", "Meaning"],
    [
      ["prevent", "Runtime blocks violation (sandbox / pre-tool hook)"],
      ["detect", "Portable postflight catches it after the fact"],
      ["cannot honor", "Gate fails closed unless explicitly waived in the open"],
    ]
  )}
  ${callout("Gold / Mint / Coral on the mark.", "UI state folds: Gold=BOUND · Mint=SETTLED · Coral=RED. Master brand logo stays Forge Gold.")}
`);

/* ── PASS 8 ── */
slide({ meta: "Pass 8 · The Loop" }, `
  <p class="eyebrow">Pass 8 · task-loop</p>
  <h2>The Loop — attempt → verify → settle</h2>
  <p class="lead">Drive <strong>one</strong> assigned task to a named terminal state. This loop never picks work — you or CI pass <span class="mono">--issue</span>.</p>
  <div class="diagram-wrap mt">${SVG_LOOP}</div>
  ${callout("Four properties of a real loop.", "Fresh process each attempt · three-axis budgets checked before the call · stagnation beats fixed count · exhaustion is a planned landing with HANDOFF.md.")}
`);

slide({ meta: "Pass 8 · Terminal states" }, `
  <p class="eyebrow">Pass 8 · TASK_LOOP=</p>
  <h2>An error is never a success</h2>
  ${table(
    ["State", "Exit 0?", "Meaning · your action"],
    [
      ["<span class=\"mono\">SETTLED</span>", "yes", "Green + PR — review &amp; merge"],
      ["<span class=\"mono\">LOCAL_SETTLED</span>", "yes", "Green local commit (external_writes deny) — correct, not failure"],
      ["<span class=\"mono\">NO_OP</span>", "yes", "Already green on arrival"],
      ["<span class=\"mono\">BLOCKED</span>", "no", "Human / missing upstream — read blocked report"],
      ["<span class=\"mono\">STALLED</span>", "no", "Same failure N times — stop burning money; fix cause"],
      ["<span class=\"mono\">EXHAUSTED</span>", "no", "Budget hit · HANDOFF.md · <span class=\"mono\">--resume</span>"],
      ["<span class=\"mono\">CANCELLED</span>", "no", "<span class=\"mono\">cvg/loop/&lt;id&gt;/STOP</span> honored"],
      ["<span class=\"mono\">ERROR</span>", "no", "Loop unsafe — investigate environment"],
    ]
  )}
`);

slide({ meta: "Pass 8 · Settlement" }, `
  <p class="eyebrow">Pass 8 · settlement &amp; verify</p>
  <h2>Scoped, ordered, policy-governed</h2>
  ${steps([
    ["Stage only authorized paths", "From capability envelope <span class=\"mono\">fs.write</span> — never <span class=\"mono\">git add -A</span> (untracked files would slip past diff guards)."],
    ["External writes are separate", "Default deny → LOCAL_SETTLED. Push/PR require policy or <span class=\"mono\">--allow-external-writes</span>. Commit, push, tracker, PR are four effects."],
    ["Receipt last", "A pass receipt never attests a settlement that didn’t happen."],
    ["Optional tier-2", "<span class=\"mono\">cvg verify --task … --judge &lt;other-family&gt;</span> · holdout worker never saw · <span class=\"mono\">CHECK_VERIFY=UPHELD|REFUTED|UNAVAILABLE</span>"],
    ["Accept + next", "<span class=\"mono\">cvg tasks accept</span> · then <span class=\"mono\">cvg ready</span> for next unblocked leaf"],
  ])}
`);

/* ── WORKED EXAMPLE ── */
slide({ meta: "Worked example" }, `
  <p class="eyebrow">04 · FULL descent dress rehearsal</p>
  <h2>Storm-alerts feed · end to end</h2>
  <p class="lead">One concrete product idea through every pass — files, tokens, and your moves.</p>
  ${steps([
    ["Day 0 · Setup", "<span class=\"mono\">cvg init · setup signing · setup</span> → READY. <span class=\"mono\">cvg lane \"customer storm-alerts feed\"</span> → FULL. <span class=\"mono\">cvg next --lane FULL</span> → NEXT_PASS=0."],
    ["Design 0–4", "BRD → tech-spec → ADRs → swimlanes (ingest · deliver · steel-thread) → Codex attack → triage objections → <strong>you sign barrier</strong>."],
    ["Build 5–8", "Seal steel-thread task first (evals first) · optional Linear register · bind · loop until <span class=\"mono\">TASK_LOOP=SETTLED</span>."],
    ["Between tasks", "<span class=\"mono\">cvg ready</span> → next unblocked leaf → bind → loop until frontier empty."],
  ])}
`);

slide({ meta: "Worked example · board" }, `
  <p class="eyebrow">04 · evidence board at end</p>
  <h2>What green looks like</h2>
  ${table(
    ["Pass", "Evidence on disk", "Token"],
    [
      ["0", "cvg/docs/brd/storm-alerts-feed.md", "CHECK_BRD=PASS"],
      ["1", "cvg/docs/tech-spec/…", "CHECK_TECH_SPEC=PASS"],
      ["2", "cvg/docs/adrs/* + CONTEXT.md", "CHECK_ADR=OK"],
      ["3–4", "swimlanes/** + .consensus/", "CHECK_PLAN + CHECK_CONSENSUS"],
      ["5", "cvg/tasks/T-*.md sealed", "TIER=1"],
      ["7", "cvg/execution/&lt;id&gt;/", "CHECK_RUNTIME_CONTRACT=PASS"],
      ["8", "PR + receipts/", "TASK_LOOP=SETTLED"],
    ]
  )}
  ${callout("Steering phrases.", "“FULL lane. cvg next.” · “I’ll sign when draft is green.” · “No build verbs in ADRs.” · “Dispatch Codex; I sign.” · “Evals first; stamp when I say.” · “Report the token only.”")}
`);

/* ── OPERATIONS ── */
slide({ meta: "Token literacy" }, `
  <p class="eyebrow">05 · Greppable truth</p>
  <h2>Token glossary</h2>
  ${table(
    ["Token", "Means"],
    [
      ["CHECK_BRD=PASS", "Brief handoff-ready"],
      ["CHECK_TECH_SPEC=PASS", "Spec handoff-ready"],
      ["CHECK_ADR=OK", "Terrain recorded"],
      ["CHECK_PLAN=OK", "Swimlane tree sound (machine subset)"],
      ["CHECK_CONSENSUS=OK", "Barrier machine-half green"],
      ["TIER=1 / DELEGATE", "Spec sealed"],
      ["CHECK_REGISTER=OK", "Board mirrors backlog"],
      ["CHECK_RUNTIME_CONTRACT=PASS", "Bound to host"],
      ["TASK_LOOP=SETTLED", "Shipped through outward legs"],
      ["NEXT_PASS=DONE", "Descent complete for that lane"],
      ["CHECK_LESSON=PASS", "Lesson structurally teachable"],
      ["CHECK_VERIFY=UPHELD|REFUTED", "Tier-2 independent judge"],
    ]
  )}
`);

slide({ meta: "Authority" }, `
  <p class="eyebrow">05 · Your authority</p>
  <h2>What only you must do</h2>
  ${table(
    ["Pass", "You must personally…"],
    [
      ["0", "Answer grill · canonical on BRD · or no-go"],
      ["1", "Close blockers · canonical on tech-spec"],
      ["2", "Accept terrain facts · refuse design-as-ADR"],
      ["3", "Approve seams / steel thread / owners"],
      ["4", "<strong>Resolve objections · sign the barrier</strong>"],
      ["5", "Authorize stamp · place holdouts"],
      ["6", "Connect tracker (if used) · verify board truth"],
      ["7", "Host readiness · fence / waiver honesty"],
      ["8", "Assign issue · interpret terminal states · accept / merge"],
    ]
  )}
`);

slide({ meta: "Day-to-day" }, `
  <p class="eyebrow">05 · Operating model</p>
  <h2>Any work day · four control surfaces</h2>
  ${cards([
    ["gold-edge", "LANE", "How much ceremony?", "<span class=\"mono\">cvg lane</span> — FAST / NORMAL / FULL with hard floors"],
    ["", "NEXT", "Where am I?", "<span class=\"mono\">cvg next</span> — evidence board + prompt + gate"],
    ["", "GATE", "Is this pass true?", "<span class=\"mono\">cvg capture|intent|structure|…</span>"],
    ["mint-edge", "TOKEN", "Can I trust it?", "One greppable line. Agents and owners read the same truth."],
  ], 4)}
  ${steps([
    ["Start session", "<span class=\"mono\">cvg setup</span> healthy → <span class=\"mono\">cvg lane</span> → <span class=\"mono\">cvg next --lane …</span>"],
    ["During pass", "Agent follows pass-prompt. You answer decisions only. Gate token green before moving on."],
    ["Build half", "<span class=\"mono\">cvg ready</span> → bind → loop. Never edit sealed evals to force green."],
  ])}
`);

// CLOSE
slide({ meta: "Remember" }, `
  <p class="eyebrow">06 · Closing</p>
  <h2>You are converged when<br><span class="gold">the eval passes</span><br>— not when you feel done.</h2>
  ${cards([
    ["", "Design", "Precision first", "Cheap kills early. Soft intent poisons every later pass."],
    ["gold-edge", "Barrier", "Your signature", "Cross-family attack + human sign-off before machines build."],
    ["mint-edge", "Build", "Named states only", "SETTLED is success. EXHAUSTED is a landing, not a win."],
  ])}
  ${callout("Chat is the UX.", "Disk + tokens are the truth.")}
`);

slide({ cover: true, proof: "Settlement Fold · brand-kit-v1" }, `
  <img class="cover-icon" src="converge-icon-color-light.svg" width="84" height="84" alt="">
  <p class="eyebrow">End of handbook</p>
  <h1 style="font-size:clamp(40px,6vw,72px)">Done is<br><em style="color:var(--gold);font-style:normal">proven.</em></h1>
  <p class="tagline" style="margin-top:22px;font-size:17px;color:var(--steel)">Converge · Owner's handbook · complete edition v2</p>
  <p class="proof-line" style="margin-top:10px">Compile intent into shipped software.</p>
  <div class="cover-meta" style="margin-top:36px">
    <span><b>CLI</b> · cvg</span>
    <span><b>Skills</b> · 12</span>
    <span><b>Passes</b> · 0–8</span>
    <span><b>Identity</b> · Settlement Fold</span>
  </div>
`);

/* ── CSS + HTML shell ── */
const total = n;
const css = `
:root{
  --factory-black:var(--converge-factory-black,#070a0f);
  --carbon:var(--converge-carbon,#111720);
  --graphite:var(--converge-graphite,#29313a);
  --steel:var(--converge-steel,#8d99a6);
  --ivory:var(--converge-proof-ivory,#f5f2ea);
  --gold:var(--converge-forge-gold,#f3b64c);
  --mint:var(--converge-settlement-mint,#73e2c3);
  --coral:var(--converge-verdict-coral,#ff6b64);
  --gold-soft:rgba(243,182,76,.12);
  --mint-soft:rgba(115,226,195,.12);
  --coral-soft:rgba(255,107,100,.12);
  --line:rgba(141,153,166,.16);
  --line-strong:rgba(141,153,166,.32);
  --grid:rgba(243,182,76,.04);
  --sans:"Avenir Next",Inter,ui-sans-serif,system-ui,sans-serif;
  --mono:Menlo,"IBM Plex Mono",ui-monospace,monospace;
}
*{box-sizing:border-box}
html,body{margin:0;background:var(--factory-black);color:var(--ivory);font-family:var(--sans);-webkit-font-smoothing:antialiased}
html{scroll-snap-type:y mandatory;scroll-behavior:smooth}
body::before{content:"";pointer-events:none;position:fixed;inset:0;z-index:100;opacity:.03;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")}

.deck{width:100%}
.slide{position:relative;width:100%;height:100dvh;height:100vh;scroll-snap-align:start;scroll-snap-stop:always;overflow:hidden;display:flex;flex-direction:column;padding:32px 44px 24px}
.page-bg{position:absolute;inset:0;z-index:0;pointer-events:none}
.page-bg .grid{position:absolute;inset:0;background-image:linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);background-size:44px 44px;mask-image:radial-gradient(ellipse 75% 65% at 50% 40%,#000 15%,transparent 75%)}
.page-bg .glow{position:absolute;width:48vw;height:48vw;border-radius:50%;filter:blur(90px);opacity:.12}
.page-bg .glow-gold{top:-12%;right:-10%;background:var(--gold)}
.inner{position:relative;z-index:2;width:min(100%,1180px);margin:0 auto;flex:1;display:flex;flex-direction:column;min-height:0}

.chrome-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;flex-shrink:0}
.chrome-top .mark{height:22px;width:auto}
.chrome-top .meta{font:500 10px/1 var(--mono);letter-spacing:.16em;text-transform:uppercase;color:var(--steel)}
.chrome-bottom{display:flex;align-items:center;justify-content:space-between;margin-top:auto;padding-top:12px;border-top:1px solid var(--line);flex-shrink:0}
.chrome-bottom .proof{font:500 10px/1.3 var(--mono);letter-spacing:.12em;text-transform:uppercase;color:var(--steel)}
.chrome-bottom .proof em{font-style:normal;color:var(--gold)}
.page-num{font:600 11px/1 var(--mono);letter-spacing:.1em;color:var(--ivory)}
.page-num span{color:var(--steel);font-weight:400}

.eyebrow{font:600 10px/1.2 var(--mono);letter-spacing:.18em;text-transform:uppercase;color:var(--gold);margin:0 0 8px}
h1{font-weight:600;font-size:clamp(40px,6.5vw,78px);line-height:.96;letter-spacing:-.04em;margin:0 0 10px}
h1 em,.gold{color:var(--gold);font-style:normal}
h2{font-weight:600;font-size:clamp(24px,3.2vw,36px);line-height:1.08;letter-spacing:-.03em;margin:0 0 8px}
.lead{font-size:clamp(14px,1.25vw,16.5px);line-height:1.48;color:var(--steel);max-width:48em;margin:0 0 4px}
.lead strong{color:var(--ivory);font-weight:500}
.mono{font-family:var(--mono);font-size:.9em;color:var(--gold)}
.mt{margin-top:12px!important}

.cover{justify-content:center;padding-top:40px}
.cover .inner{justify-content:center;max-width:920px}
.cover-icon{width:84px;height:auto;margin-bottom:18px;filter:drop-shadow(0 0 36px rgba(243,182,76,.28))}
.cover .subtitle{font:500 12px/1.3 var(--mono);letter-spacing:.2em;text-transform:uppercase;color:var(--steel);margin:0 0 24px}
.cover .tagline{font-size:clamp(18px,2vw,24px);line-height:1.35;color:var(--ivory);margin:0 0 8px}
.cover .tagline em{font-style:normal;color:var(--gold)}
.cover .proof-line{font:500 12px/1.3 var(--mono);letter-spacing:.12em;text-transform:uppercase;color:var(--mint);margin:0 0 32px}
.cover-meta{display:flex;flex-wrap:wrap;gap:10px 22px;font:500 10px/1.3 var(--mono);letter-spacing:.08em;text-transform:uppercase;color:var(--steel)}
.cover-meta b{color:var(--ivory);font-weight:500}

.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.grid-4{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
.split{display:grid;grid-template-columns:minmax(0,0.95fr) minmax(0,1.05fr);gap:16px;align-items:start}
.card{background:color-mix(in srgb,var(--carbon) 90%,transparent);border:1px solid var(--line);border-radius:12px;padding:12px 14px;min-width:0}
.card.gold-edge{border-top:2px solid var(--gold)}
.card.mint-edge{border-top:2px solid var(--mint)}
.card.coral-edge{border-top:2px solid var(--coral)}
.card .label{font:600 9px/1 var(--mono);letter-spacing:.14em;text-transform:uppercase;color:var(--gold);margin-bottom:6px}
.card h3{font-size:14px;font-weight:600;letter-spacing:-.02em;margin:0 0 5px;color:var(--ivory)}
.card p{font-size:12px;line-height:1.42;margin:0;color:var(--steel)}
.card p strong{color:var(--ivory);font-weight:500}

.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:12px 0}
.kpi{background:var(--carbon);border:1px solid var(--line);border-radius:11px;padding:11px}
.kpi b{display:block;font-size:26px;font-weight:600;letter-spacing:-.03em;line-height:1;color:var(--ivory)}
.kpi b.gold{color:var(--gold)}.kpi b.mint{color:var(--mint)}
.kpi span{display:block;margin-top:5px;font:500 9px/1.2 var(--mono);letter-spacing:.1em;text-transform:uppercase;color:var(--steel)}

/* ── FIXED STEPS: body always in column 2 ── */
.steps{display:grid;gap:7px;counter-reset:st}
.step{
  display:grid;
  grid-template-columns:28px minmax(0,1fr);
  gap:10px;
  align-items:start;
  background:var(--carbon);
  border:1px solid var(--line);
  border-radius:10px;
  padding:10px 12px;
  counter-increment:st;
  min-width:0;
}
.step::before{
  content:counter(st,decimal-leading-zero);
  font:700 11px/1.2 var(--mono);
  color:var(--gold);
  padding-top:2px;
  grid-column:1;
  grid-row:1;
}
.step-body{
  grid-column:2;
  min-width:0; /* allow text wrap inside fr column, not 28px */
}
.step-body strong{display:block;font-size:12.5px;color:var(--ivory);font-weight:600;line-height:1.3}
.step-body p{margin:3px 0 0;font-size:11.5px;color:var(--steel);line-height:1.42}

.callout{border-left:3px solid var(--gold);background:color-mix(in srgb,var(--carbon) 75%,transparent);border-radius:0 10px 10px 0;padding:10px 12px}
.callout p{margin:0;font-size:12.5px;color:var(--ivory);line-height:1.42}
.callout p span{color:var(--steel)}

.tablebox{overflow:hidden;background:var(--carbon);border:1px solid var(--line);border-radius:12px;min-width:0}
table{width:100%;border-collapse:collapse;font-size:11.5px}
th{text-align:left;background:color-mix(in srgb,var(--graphite) 50%,var(--carbon));color:var(--steel);padding:7px 10px;font:600 9px/1.2 var(--mono);letter-spacing:.1em;text-transform:uppercase;border-bottom:1px solid var(--line-strong)}
td{padding:7px 10px;border-bottom:1px solid var(--line);color:var(--steel);vertical-align:top;line-height:1.35}
td strong{color:var(--ivory);font-weight:500}
tr:last-child td{border-bottom:0}
.compact table{font-size:11px}
.compact th,.compact td{padding:5px 9px}

.chain{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.chain-node{background:var(--carbon);border:1px solid var(--line);border-radius:10px;padding:10px 14px;font-weight:600;font-size:12px;color:var(--ivory)}
.chain-node.gold{border-color:color-mix(in srgb,var(--gold) 50%,transparent);color:var(--gold)}
.chain-node span{display:block;font:500 9px/1.2 var(--mono);color:var(--steel);margin-top:3px;font-weight:400}
.chain-arr{color:var(--gold);font:500 14px var(--mono)}

ul.chk{margin:0;padding:0;list-style:none}
ul.chk li{position:relative;padding:4px 0 4px 16px;font-size:12px;color:var(--steel);line-height:1.4}
ul.chk li::before{content:"";position:absolute;left:0;top:9px;width:7px;height:7px;border-radius:2px;border:1px solid var(--gold);background:var(--gold-soft)}
ul.chk li strong{color:var(--ivory);font-weight:500}

.diagram-wrap{width:100%;min-width:0}
.diagram{width:100%;height:auto;display:block;max-height:150px}
.diagram-md{max-height:200px}
.diagram-v{max-height:280px;width:100%}

.deck-dots{position:fixed;right:12px;top:50%;transform:translateY(-50%);z-index:40;display:flex;flex-direction:column;gap:5px;max-height:80vh;overflow:auto}
.deck-dots a{width:6px;height:6px;border-radius:50%;background:var(--graphite);border:1px solid var(--line-strong);flex-shrink:0}
.deck-dots a:hover{background:var(--gold)}

html.capture-mode .slide{opacity:1!important;transform:none!important;transition:none!important;height:900px!important;width:1440px!important;padding:28px 40px 22px}
html.capture-mode .deck-dots,html.capture-mode .deck-progress,html.capture-mode .deck-counter,html.capture-mode .deck-hints{display:none!important}
html.capture-mode body::before{display:none!important}

@media print{
  html{scroll-snap-type:none}
  .slide{height:100vh;page-break-after:always;break-after:page}
  .deck-dots,body::before{display:none}
}
`;

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Converge · Owner's Handbook · Complete v2</title>
<meta name="description" content="Complete Converge owner handbook — Settlement Fold. Full curriculum, diagrams, tables, fixed layout.">
<link rel="icon" href="converge-icon-color-light.svg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="converge-brand.css">
<style>${css}</style>
<script>
  (function () {
    if (new URLSearchParams(location.search).get('capture') !== '1') return;
    document.documentElement.classList.add('capture-mode');
    window.addEventListener('load', async () => {
      try { await document.fonts.ready; } catch (_) {}
      await new Promise(r => setTimeout(r, 600));
      window.__captureReady = true;
    });
  })();
</script>
</head>
<body>
<nav class="deck-dots" aria-label="Slides">${Array.from({ length: total }, (_, i) => `<a href="#s${String(i + 1).padStart(2, "0")}" title="Slide ${i + 1}"></a>`).join("")}</nav>
<div class="deck" id="deck">
${slides.join("\n").replace(/TOTAL/g, String(total).padStart(2, "0"))}
</div>
</body>
</html>`;

writeFileSync(out, html);
console.log(`✓ wrote ${out}`);
console.log(`  ${total} slides`);
