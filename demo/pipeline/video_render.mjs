// Renders the WhatToEat demo video from the recorded takes.
//   bun run video_render.mjs preview 2,12.5,23   -> stills (video/preview/*.png)
//   bun run video_render.mjs full                 -> ~/Downloads/WhatToEat-demo/WhatToEat-demo.mp4
import { chromium } from 'playwright';
import { readFileSync, readdirSync, mkdirSync } from 'fs';
import { spawn } from 'child_process';

const ROOT = '/private/tmp/claude-501/-Users-nivedita-Downloads-mosaic/cfcb306c-a296-425d-9f78-9042eb13f5b7/scratchpad/video';
const REPO = '/Users/nivedita/Downloads/mosaic';
const DEMO = '/Users/nivedita/Downloads/WhatToEat-demo';
const FFMPEG = `${ROOT}/node_modules/@ffmpeg-installer/darwin-arm64/ffmpeg`;
const FPS = 30, DURATION = 119.8, XF = 0.12; // crossfade at cuts
const [mode = 'preview', arg = ''] = process.argv.slice(2);

// ── Takes, events and the edit ──────────────────────────────────────────────
const takes = {};
for (const k of ['A', 'B', 'C', 'D', 'E']) {
  const L = JSON.parse(readFileSync(`${ROOT}/raw/${k}/log.json`, 'utf8'));
  const E = {};
  for (const e of L.events) {
    if (!(e.label in E)) E[e.label] = e;
  }
  const ev = (label) => E[label].t;
  const finals = L.api.filter((a) => a.name === 'intent' && a.req.includes('"final":true'));
  takes[k] = { L, E, ev, finals, ts: L.frames.map((f) => f.t), speech: E.micOpen ? E.micOpen.speech : null };
}
const A = takes.A, B = takes.B, C = takes.C, D = takes.D, E = takes.E;
const allSet = A.finals.at(-1).t + 0.05;                      // "You're all set!" appears
const loader = B.E.cookUnderstood.t + 0.05;                    // "Finding your picks…" appears
const chips = B.E.chipsShown.at + 0.05;                        // "Meal: dinner · How: dine" appear

// [outStart, outEnd, rawStart, rawEnd]; rawStart == rawEnd holds a frame.
const segA = [
  [3.5, 5.5, A.ev('getStarted') - 2.0, A.ev('getStarted')],
  [5.5, 7.5, A.ev('getStarted'), A.ev('micTap')],
  [7.5, 9.0, A.ev('micTap'), A.ev('micTap') + 1.5],
  [9.0, 18.0, A.speech - 1.0, A.ev('stopTap')],
  [18.0, 20.0, A.ev('stopTap'), allSet],
  [20.0, 21.0, allSet, allSet + 1.0],
  [21.0, 25.5, A.ev('startEating') - 4.5, A.ev('startEating')],
  [25.5, 27.0, A.ev('startEating'), A.ev('startEating') + 1.5],
  [27.0, 28.5, A.ev('startEating') + 1.5, A.ev('scrollDown:start')],
  [28.5, 34.7, A.ev('scrollDown:start'), A.ev('scrollDown:end')],
  [34.7, 35.2, A.ev('scrollDown:end'), A.ev('scrollUp:start')],
  [35.2, 37.7, A.ev('scrollUp:start'), A.ev('scrollUp:end')],
  [37.7, 39.9, A.ev('scrollUp:end'), A.ev('scrollUp:end') + 2.2],
];
// Take D: cook by voice, the meal log on the Me page, dine out by typing, Community.
const L_D = D.E.cookUnderstood.t + 0.05, chipsD = D.E.chipsShown.at + 0.05, ht = D.ev('havingThis'), vm = D.ev('viewMenu'), me = D.ev('meTab'), cm = D.ev('communityTab'), sm = D.ev('scrollMenu:start');
const segD = [
  [39.3, 39.9, D.ev('craving1') - 0.6, D.ev('craving1')],
  [39.9, 41.4, D.ev('craving1'), D.ev('craving1') + 1.5],
  [41.4, 41.9, D.ev('micTap') - 0.01, D.ev('micTap') - 0.01],
  [41.9, 42.9, D.ev('micTap'), D.ev('micTap') + 1.0],
  [42.9, 49.9, D.speech - 1.0, D.ev('stopTap')],
  [49.9, 50.5, D.ev('stopTap'), D.ev('stopTap') + 0.6],
  [50.5, 51.0, L_D - 0.5, L_D],
  [51.0, 53.6, L_D, L_D + 2.6],
  [53.6, 56.6, D.ev('viewRecipe') - 3.0, D.ev('viewRecipe')],
  [56.6, 57.6, D.ev('viewRecipe'), D.ev('viewRecipe') + 1.0],
  [57.6, 58.2, D.ev('recipeReady') - 0.6, D.ev('scrollRecipe:start')],
  [58.2, 62.7, D.ev('scrollRecipe:start'), D.ev('scrollRecipe:end')],
  [62.7, 63.2, D.ev('scrollRecipe:end'), ht],
  // The meal log: Home with "Meal logged!", then the Me page. The Me page was recorded after
  // dining out, but that adds nothing to Meal history, so it shows the same log.
  [63.2, 64.6, ht, ht + 1.4],
  [64.6, 65.8, me, me + 1.2],
  [65.8, 68.7, me + 1.2, cm - 0.05],
  [68.7, 69.1, D.ev('craving2') - 0.4, D.ev('craving2')],
  [69.1, 70.1, D.ev('craving2'), D.ev('typeInstead')],
  [70.1, 71.1, D.ev('typeInstead'), D.ev('textClick')],
  [71.1, 74.1, D.ev('textClick'), chipsD],
  [74.1, 75.1, D.ev('continue') - 1.0, D.ev('continue')],
  [75.1, 76.1, D.ev('continue'), D.ev('continue') + 1.0],
  [76.1, 77.6, D.ev('spicy') - 1.5, D.ev('spicy')],
  [77.6, 78.4, D.ev('spicy'), D.ev('next')],
  [78.4, 79.6, D.ev('next'), D.ev('casual')],
  [79.6, 80.6, D.ev('casual'), D.ev('casual') + 1.0],
  [80.6, 82.4, D.ev('casual') + 1.0, D.ev('casual') + 2.8],
  [82.4, 87.2, vm - 4.8, vm],
  [87.2, 88.2, vm, vm + 1.0],
  [88.2, 89.2, D.ev('menuReady') - 1.0, sm],
  // Scroll only as far as Find on Google Maps stays on screen, then hold for the Maps line.
  [89.2, 92.2, sm, sm + 3.0],
  [92.2, 94.9, sm + 3.0, sm + 3.0],
  // Community comes after ordering in (take C), straight from the Me page.
  [105.7, 106.3, cm - 0.6, cm],
  [106.3, 108.6, cm, cm + 2.3],
  [108.6, 110.6, D.ev('scrollCommunity:start'), D.ev('scrollCommunity:end')],
  [110.6, 111.8, D.ev('scrollCommunity:end'), D.ev('scrollCommunity:end') + 1.2],
];
const chipsC = C.E.chipsShown.at + 0.05, loaderC = C.E.orderUnderstood.at + 0.05, sw = C.ev('swiggy');
const segC = [
  [94.3, 94.9, C.ev('craving') - 0.6, C.ev('craving')],
  [94.9, 95.7, C.ev('craving'), C.ev('typeInstead')],
  [95.7, 96.4, C.ev('typeInstead'), C.ev('textClick')],
  [96.4, 98.4, C.ev('textClick'), C.ev('typing:end')],
  [98.4, 98.9, chipsC - 0.1, chipsC + 0.4],
  [98.9, 99.5, C.ev('continue'), C.ev('continue') + 0.6],
  [99.5, 100.5, loaderC + 0.1, loaderC + 1.1],
  [100.5, 103.8, sw - 3.3, sw],
  [103.8, 106.2, sw, sw + 2.4],
];
// Which take is on screen, by time; cross-fades happen under the doodle wipes.
const SWITCHES = [[39.45, 39.75, 'A', 'D'], [94.45, 94.75, 'D', 'C'], [105.85, 106.15, 'C', 'D']];
const SEGS = { A: segA, C: segC, D: segD };

// ── The nudge scene, and the trims that make room for it ────────────────────
// The edit above is in the previous cut's timing; W() maps it onto this one. Each trim is
// [from, to, new length] in the old timing; the nudge scene (take E) opens at INS.
const TRIMS = [[25.5, 28.5, 2.2], [58.2, 62.7, 3.5], [65.8, 68.7, 2.5], [69.1, 71.1, 1.6], [71.1, 74.1, 2.2],
  [80.6, 82.4, 1.0], [96.4, 98.4, 1.4], [99.5, 100.5, 0.6], [106.3, 108.6, 1.6]];
const INS = 68.7, NUDGE = 6.4;
const W = (t, end = false) => {
  let out = t;
  for (const [a, b, len] of TRIMS) {
    if (t >= b) out -= (b - a) - len;
    else if (t > a) out -= (t - a) * (1 - len / (b - a));
  }
  return out + ((end ? t > INS : t >= INS) ? NUDGE : 0);
};
for (const segs of [segA, segD, segC]) for (const sg of segs) { sg[1] = W(sg[1], true); sg[0] = W(sg[0]); }
for (const sw of SWITCHES) { sw[0] = W(sw[0]); sw[1] = W(sw[1]); }
// Take E: Home after a heavy breakfast and lunch, the nudge, then light dinner picks.
const N0 = W(INS, true), tapE = E.ev('nudgeTap'), picksE = E.E.picksShown.at;
const segE = [
  [N0 - 0.4, N0 + 2.4, tapE - 2.8, tapE],
  [N0 + 2.4, N0 + 3.4, tapE, tapE + 1.0],
  [N0 + 3.4, N0 + 4.1, tapE + 2.0, tapE + 2.7],
  [N0 + 4.1, N0 + NUDGE + 0.3, picksE + 1.0, picksE + NUDGE - 2.8],
];
SEGS.E = segE;
SWITCHES.push([N0 - 0.15, N0 + 0.15, 'D', 'E'], [N0 + NUDGE - 0.15, N0 + NUDGE + 0.15, 'E', 'D']);
SWITCHES.sort((p, q) => p[0] - q[0]);

const rawIn = (segs, t) => {
  let i = segs.findIndex(([o0, o1]) => t >= o0 && t < o1);
  if (i < 0) {
    let best = 0, gap = Infinity;
    segs.forEach(([o0, o1], k) => { const g = t < o0 ? o0 - t : t - o1; if (g < gap) { gap = g; best = k; } });
    i = best;
  }
  const [o0, o1, r0, r1] = segs[i];
  const tt = Math.max(o0, Math.min(o1, t));
  return { i, raw: r0 + (tt - o0) * (r1 - r0) / (o1 - o0) };
};
const frameUrl = (take, raw) => {
  const T = takes[take];
  let lo = 0, hi = T.ts.length - 1;
  while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (T.ts[mid] <= raw) lo = mid; else hi = mid - 1; }
  return `file://${ROOT}/raw/${take}/frames/${String(T.L.frames[lo].i).padStart(6, '0')}.jpg`;
};
const layerFor = (take, segs, t) => {
  const { i, raw } = rawIn(segs, t);
  const base = { src: frameUrl(take, raw) };
  const [o0] = segs[i];
  if (i > 0 && t - o0 < XF) {
    const [p0, p1, q0, q1] = segs[i - 1];
    if (Math.abs(q1 - segs[i][2]) > 0.04) {           // a real cut: cross-fade from the previous shot
      const prevRaw = q1 + (t - o0) * (q1 - q0) / (p1 - p0 || 1);
      return [{ src: frameUrl(take, prevRaw) }, { ...base, op: (t - o0) / XF }];
    }
  }
  return [base];
};
const phoneLayers = (t) => {
  for (const [s0, s1, from, to] of SWITCHES) {
    if (t >= s0 && t < s1) return [layerFor(from, SEGS[from], t)[0], { ...layerFor(to, SEGS[to], t)[0], op: (t - s0) / (s1 - s0) }];
  }
  let take = 'A';
  for (const [s0, , , to] of SWITCHES) if (t >= s0) take = to;
  return layerFor(take, SEGS[take], t);
};
// Out time of a raw event (for click rings).
const outOf = (segs, raw) => {
  for (const [o0, o1, r0, r1] of segs) if (r1 > r0 && raw >= r0 - 1e-6 && raw <= r1 + 1e-6) return o0 + (raw - r0) * (o1 - o0) / (r1 - r0);
  return null;
};
const clicks = [];
for (const [take, segs, labels] of [
  ['A', segA, ['getStarted', 'micTap', 'stopTap', 'startEating']],
  ['D', segD, ['craving1', 'micTap', 'stopTap', 'viewRecipe', 'havingThis', 'meTab', 'craving2', 'typeInstead', 'textClick', 'continue', 'spicy', 'next', 'casual', 'viewMenu', 'communityTab']],
  ['C', segC, ['craving', 'typeInstead', 'textClick', 'continue', 'swiggy']],
  ['E', segE, ['nudgeTap']],
]) {
  for (const label of labels) {
    const e = takes[take].E[label];
    const t = outOf(segs, e.t);
    if (t == null) { console.log('click not in the cut:', take, label); continue; }
    clicks.push({ t, dx: e.x * 1.1, dy: e.y * 1.1, label });
  }
}

// ── Captions and graphics (the script's On-screen text) ─────────────────────
const words = JSON.parse(readFileSync(`${ROOT}/word_times.json`, 'utf8'));
const doodleDir = `${REPO}/assets/doodles`;
const doodles = readdirSync(doodleDir).filter((f) => f.endsWith('.png')).sort().map((f) => `file://${doodleDir}/${f}`);
let seed = 11;
const rnd = () => { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; };
const parade = (t0) => {
  const pick = [];
  while (pick.length < 8) { const d = doodles[Math.floor(rnd() * doodles.length)]; if (!pick.includes(d)) pick.push(d); }
  return { t0, doodles: pick, sizes: pick.map(() => 230 + rnd() * 80), phase: pick.map((_, i) => i * 0.55), dy: pick.map(() => (rnd() - 0.5) * 120) };
};
const config = {
  doodles,
  badge: `file://${REPO}/web/icons/Icon-512.png`,
  phone: { in: 3.65, out: 111.4 },
  titleOut: 3.65, endIn: 111.75, endPill: 112.9, endUrl: 115.0, fadeAt: 118.4,
  pills: [
    { text: '1 · Set up by voice', t0: 3.65, t1: 27.0 },
    { text: '2 · Your home screen', t0: 27.0, t1: 39.6 },
    { text: '3 · Cook with what you have', t0: 39.6, t1: 63.6 },
    { text: '4 · Your meal log', t0: 63.6, t1: 68.7 },
    { text: '6 · Going out tonight', t0: 68.7, t1: 94.6 },
    { text: '7 · Ordering in', t0: 94.6, t1: 106.0 },
    { text: '8 · Community', t0: 106.0, t1: 111.2 },
  ],
  cards: [
    { html: 'Just <b>tell</b> it your food preferences', sub: 'No forms. One sentence sets up your profile.', t0: 5.5, t1: 18.0 },
    { html: '“Dosas and chaat” <b>→</b> South Indian + Street Food', sub: 'It reads meaning, not keywords', t0: 20.0, t1: 25.5, sparkles: true },
    { html: '<b>Every</b> meal starts here', sub: 'Changes with the time of day', t0: 27.0, t1: 34.7 },
    { html: 'It helps with all <b>three</b>', sub: 'Cooking at home, ordering in and dining out', t0: 35.0, t1: 39.4 },
    { html: 'Say what’s in your <b>kitchen</b>', t0: 39.9, t1: 49.9 },
    { html: 'Picks that fit your <b>diet</b>', sub: 'All vegetarian, like your profile', t0: 49.9, t1: 56.4 },
    { html: 'A recipe written for your <b>fridge</b>', sub: 'Built around the ingredients you have', t0: 56.6, t1: 63.2, sparkles: true },
    { html: 'Your daily <b>log</b>', sub: 'Every meal you pick, with its calories', t0: 63.8, t1: 68.4 },
    { html: 'Or just <b>type</b> it', t0: 69.1, t1: 75.1 },
    { html: 'Asks only what’s <b>missing</b>', t0: 76.1, t1: 80.6 },
    { html: '<b>Places</b> to go, not calories to count', sub: 'Each with a suggested order', t0: 82.4, t1: 87.2, sparkles: true },
    { html: 'What to <b>order</b>, with prices', sub: 'Plus a Google Maps link', t0: 88.2, t1: 94.4 },
    { html: 'Too tired to cook? <b>Order</b> in', sub: 'Same box, plain words', t0: 94.9, t1: 99.5 },
    { html: 'Ready to order on <b>Swiggy</b>', sub: 'Calories on every pick', t0: 100.5, t1: 106.0 },
    { html: 'Recipes people <b>love</b>', sub: 'Filtered to your diet', t0: 106.3, t1: 111.2 },
  ],
  voices: [
    { id: 'V1', t0: 10.0, t1: 18.5, words: words.U1 },
    { id: 'V2', t0: 43.9, t1: 50.4, words: words.U2 },
  ],
  tags: [
    { text: 'Picked up as you speak', t0: 15.4, t1: 18.0, keys: [[15.4, 312, 644], [17.5, 312, 644], [17.7, 377, 613], [18.3, 377, 613]] },
    { text: '5 answers from 1 sentence', t0: 51.0, t1: 53.6, keys: [[51.0, 381, 665]] },
    { text: 'Lighter version: fewer kcal', t0: 54.1, t1: 56.4, keys: [[54.1, 414, 645]] },
    { text: 'Saved with its calories', t0: 65.6, t1: 68.4, keys: [[65.6, 430, 731]] },
    { text: 'Dinner + dining out', t0: 74.1, t1: 75.1, keys: [[74.1, 214, 738]] },
    { text: 'Veg only, as per your profile', t0: 88.2, t1: 89.2, keys: [[88.2, 446, 713]] },
    { text: 'Opens in Google Maps', t0: 92.3, t1: 94.4, keys: [[92.3, 436, 273]] },
    { text: 'Opens Swiggy, dish already searched', t0: 103.9, t1: 106.0, keys: [[103.9, 246, 676]] },
  ],
  zooms: [
    { t0: 20.5, t1: 24.5, fx: 241, fy: 506 },
    { t0: 58.6, t1: 61.6, fx: 40, fy: 600 },
    { t0: 71.1, t1: 75.1, fx: 150, fy: 700 },
  ],
  clicks,
  parades: [parade(3.3), parade(39.25), parade(94.25), parade(105.65), parade(111.05)],
};

// Onto this cut's timing, plus the nudge scene's text.
const wv = (o) => { o.t0 = W(o.t0); o.t1 = W(o.t1, true); if (o.keys) o.keys = o.keys.map(([t, x, y]) => [W(t), x, y]); };
for (const list of [config.pills, config.cards, config.tags, config.zooms, config.voices]) list.forEach(wv);
config.parades.forEach((pd) => { pd.t0 = W(pd.t0); });
for (const k of ['titleOut', 'endIn', 'endPill', 'endUrl', 'fadeAt']) config[k] = W(config[k]);
config.phone = { in: W(config.phone.in), out: W(config.phone.out) };
config.pills.push({ text: '5 · Gentle nudges', t0: N0, t1: N0 + NUDGE });
config.cards.push({ html: 'Heavy day? Go <b>light</b>', sub: 'It nudges you toward a light dinner', t0: N0 + 0.3, t1: N0 + NUDGE - 0.3 });
config.zooms.push({ t0: N0 + 0.4, t1: N0 + 2.4, fx: 242, fy: 432 });
config.tags.push({ text: 'Light and easy to digest', t0: N0 + 4.5, t1: N0 + NUDGE - 0.3, keys: [[N0 + 4.5, 296, 552]] });
config.parades.push(parade(N0 - 0.2), parade(N0 + NUDGE - 0.2));
for (const list of [config.pills, config.cards, config.tags, config.zooms, config.parades]) list.sort((p, q) => p.t0 - q.t0);

// ── Render ──────────────────────────────────────────────────────────────────
const browser = await chromium.launch({ headless: true, args: ['--allow-file-access-from-files'] });
const page = await (await browser.newContext({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 })).newPage();
page.on('pageerror', (e) => console.log('PAGEERROR', e.message));
await page.goto(`file://${ROOT}/stage.html`);
await page.evaluate((c) => window.setup(c), config);
const draw = async (t) => {
  await page.evaluate(([tt, layers]) => window.frame(tt, layers), [t, phoneLayers(t)]);
};

if (mode === 'preview') {
  mkdirSync(`${ROOT}/preview`, { recursive: true });
  for (const t of arg.split(',').map(Number)) {
    await draw(t);
    await page.screenshot({ path: `${ROOT}/preview/t${t.toFixed(2).padStart(6, '0')}.png` });
    console.log('preview', t);
  }
} else {
  const out = `${DEMO}/WhatToEat-demo.mp4`;
  const ff = spawn(FFMPEG, ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-i', `${DEMO}/demo-audio-track.wav`, '-map', '0:v', '-map', '1:a',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-r', String(FPS),
    '-c:a', 'aac', '-b:a', '192k', '-ac', '2', '-shortest', '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const N = Math.round(DURATION * FPS);
  const started = Date.now();
  for (let k = 0; k < N; k++) {
    const t = k / FPS;
    await draw(t);
    const jpg = await page.screenshot({ type: 'jpeg', quality: 94 });
    if (!ff.stdin.write(jpg)) await new Promise((r) => ff.stdin.once('drain', r));
    if (k % 150 === 0) console.log(`frame ${k}/${N}  t=${t.toFixed(1)}s  ${((Date.now() - started) / 1000).toFixed(0)}s elapsed`);
  }
  ff.stdin.end();
  await new Promise((r) => ff.on('close', r));
  console.log('wrote', out);
}
await browser.close();
