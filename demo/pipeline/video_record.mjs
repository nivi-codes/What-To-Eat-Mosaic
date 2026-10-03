// Records one take of the demo from the live app.
//   bun run record.mjs A|B
// Frames come from the browser's screencast (JPEG, with swap timestamps); every action,
// the mic opening and every API reply is logged with epoch seconds for the edit.
import { chromium } from 'playwright';
import { mkdirSync, rmSync, writeFileSync } from 'fs';

const TAKE = process.argv[2];
const ROOT = '/private/tmp/claude-501/-Users-nivedita-Downloads-mosaic/cfcb306c-a296-425d-9f78-9042eb13f5b7/scratchpad/video';
const MIC = {
  A: '/Users/nivedita/Downloads/WhatToEat-demo/voice-input/U1-onboarding-mic.wav',
  B: '/Users/nivedita/Downloads/WhatToEat-demo/voice-input/U2-cook-mic.wav',
  C: '/Users/nivedita/Downloads/WhatToEat-demo/voice-input/U2-cook-mic.wav', // not used: take C types
  D: '/Users/nivedita/Downloads/WhatToEat-demo/voice-input/U2-cook-mic.wav',
  E: '/Users/nivedita/Downloads/WhatToEat-demo/voice-input/U2-cook-mic.wav', // not used: take E has no voice
}[TAKE];
const OUT = `${ROOT}/raw/${TAKE}`;
const ONBOARDING = "I'm vegetarian. I'm a big fan of dosas and chaat, I love spicy food, I have no allergies, and I prefer healthy options.";
const MIC_LEAD = 4.0; // seconds of silence before the prompt in the -mic file

rmSync(OUT, { recursive: true, force: true });
mkdirSync(`${OUT}/frames`, { recursive: true });

const now = () => Date.now() / 1000;
const t0 = now();
const log = { take: TAKE, events: [], api: [], frames: [] };
const mark = (label, extra = {}) => {
  log.events.push({ label, t: now(), ...extra });
  console.log(`${(now() - t0).toFixed(1).padStart(6)} ${label}`);
};

const browser = await chromium.launch({
  headless: true,
  args: ['--force-device-scale-factor=1.1', '--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', `--use-file-for-fake-audio-capture=${MIC}`],
});
// The phone frame is 876 CSS px tall; at 1.1x it renders at ~964 px, close to its final 960.
const ctx = await browser.newContext({
  viewport: { width: 440, height: 920 },
  deviceScaleFactor: 1.1,
  permissions: ['microphone'],
  timezoneId: process.env.TZID || 'America/Noronha', // an evening clock, so the home screen says "tonight"
});
await ctx.addInitScript(() => {
  window.__gum = [];
  const md = navigator.mediaDevices;
  const orig = md.getUserMedia.bind(md);
  md.getUserMedia = async (c) => { const s = await orig(c); window.__gum.push(Date.now() / 1000); return s; };
});
const page = await ctx.newPage();
page.on('response', async (r) => {
  if (!r.url().includes('/api/')) return;
  const name = r.url().split('/api/')[1].split('?')[0];
  const entry = { name, t: now(), status: r.status(), req: (r.request().postData() || '').slice(0, 200) };
  try {
    const j = await r.json();
    if (name === 'intent') entry.detected = j.detected;
    if (name === 'suggestions') entry.items = j.map((s) => ({ title: s.title, photo: Boolean(s.imageUrl), healthy: Boolean(s.hasHealthyVersion) }));
  } catch {}
  log.api.push(entry);
  console.log(`${(now() - t0).toFixed(1).padStart(6)}   api ${entry.status} ${name}${entry.detected ? ' ' + JSON.stringify(entry.detected) : ''}${entry.items ? ' ' + JSON.stringify(entry.items) : ''}`);
});

const cdp = await ctx.newCDPSession(page);
let n = 0;
cdp.on('Page.screencastFrame', async ({ data, metadata, sessionId }) => {
  const i = n++;
  writeFileSync(`${OUT}/frames/${String(i).padStart(6, '0')}.jpg`, Buffer.from(data, 'base64'));
  log.frames.push({ i, t: metadata.timestamp, recv: now() });
  try { await cdp.send('Page.screencastFrameAck', { sessionId }); } catch {}
});

const sleep = (ms) => page.waitForTimeout(ms);
const click = async (x, y, label) => { await page.mouse.click(x, y); mark(label, { x, y }); };
const typeText = async (text, label) => {
  mark(`${label}:start`);
  for (const ch of text) { await page.keyboard.type(ch); await sleep(95); }
  mark(`${label}:end`);
};
// Smooth wheel scroll: small steps at ~30 Hz.
const scroll = async (total, seconds, label) => {
  await page.mouse.move(220, 500);
  const steps = Math.round(seconds * 30);
  mark(`${label}:start`);
  for (let i = 0; i < steps; i++) { await page.mouse.wheel(0, total / steps); await sleep(1000 / 30 - 4); }
  mark(`${label}:end`);
};
const apiCount = (name) => log.api.filter((a) => a.name === name).length;
const waitApi = async (name, after, pred = () => true, timeout = 40000) => {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const hit = log.api.find((a) => a.name === name && a.t > after && pred(a));
    if (hit) return hit;
    await sleep(100);
  }
  throw new Error(`timed out waiting for ${name}`);
};
// The streaming getUserMedia call (the last one) starts the fake mic file from the top.
const micOpen = async (after) => {
  const start = Date.now();
  while (Date.now() - start < 15000) {
    const gum = await page.evaluate(() => window.__gum);
    const opens = gum.filter((t) => t > after);
    if (opens.length >= 2 || (opens.length === 1 && Date.now() - start > 4000)) return opens.at(-1);
    await sleep(50);
  }
  throw new Error('mic never opened');
};
const until = async (epoch) => { const ms = (epoch - now()) * 1000; if (ms > 0) await sleep(ms); };

await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: 484, maxHeight: 1012, everyNthFrame: 1 });
// Take E opens on a day that already has a heavy breakfast and lunch logged.
await page.goto(`https://mosaic-seven-henna.vercel.app/${TAKE === 'E' ? '?demo=heavy-day' : ''}`, { waitUntil: 'load' });
await sleep(8000);
mark('welcome');

try {
  if (TAKE === 'A') {
    await sleep(2500);
    await click(220, 760, 'getStarted');
    await sleep(2000);
    const tap = now();
    await click(220, 685, 'micTap');
    const open = await micOpen(tap);
    mark('micOpen', { at: open, speech: open + MIC_LEAD });
    await until(open + MIC_LEAD + 8.0);
    await click(220, 685, 'stopTap');
    await sleep(13000);
    await click(220, 754, 'startEating');
    await sleep(3500);
    await scroll(1440, 4, 'scrollDown');
    await sleep(500);
    await scroll(-1500, 1.5, 'scrollUp');
    await sleep(3000);
  } else if (TAKE === 'E') {
    // The light-dinner nudge: onboarding by typing (off camera), then the nudge on Home.
    await click(220, 760, 'getStarted');
    await sleep(2500);
    await click(396, 121, 'keyboard');
    await sleep(1500);
    await click(220, 650, 'onbField');
    await sleep(500);
    const typed = now();
    await page.keyboard.type(ONBOARDING, { delay: 20 });
    await sleep(2500);
    await click(220, 750, 'onbContinue');
    await waitApi('intent', typed, (a) => a.req.includes('"final":true'));
    await sleep(6000);
    await click(220, 754, 'startEating');
    await sleep(5000);
    mark('homeReady');
    if (process.env.EXPLORE) {
      await page.screenshot({ path: `${OUT}/home.png` });
    } else {
      await sleep(4000);
      const x = Number(process.env.NX), y = Number(process.env.NY);
      await click(x, y, 'nudgeTap');
      const tapAt = now();
      const sug = await waitApi('suggestions', tapAt);
      mark('picksShown', { at: sug.t });
      await sleep(6000);
      await scroll(500, 1.5, 'scrollPicks');
      await sleep(2500);
      await page.goBack().catch(() => {});
      await sleep(1000);
    }
  } else if (TAKE === 'D') {
    // One continuous run: cook by voice, log it, dine out by typing, then the Me page and Community.
    await click(220, 760, 'getStarted');
    await sleep(2500);
    await click(396, 121, 'keyboard');
    await sleep(1500);
    await click(220, 650, 'onbField');
    await sleep(500);
    const typed = now();
    await page.keyboard.type(ONBOARDING, { delay: 20 });
    await sleep(2500);
    await click(220, 750, 'onbContinue');
    await waitApi('intent', typed, (a) => a.req.includes('"final":true'));
    await sleep(6000);
    await click(220, 754, 'startEating');
    await sleep(5000);
    mark('homeReady');

    // Cook by voice.
    await click(220, 260, 'craving1');
    await sleep(1500);
    const tap = now();
    await click(220, 646, 'micTap');
    const open = await micOpen(tap);
    mark('micOpen', { at: open, speech: open + MIC_LEAD });
    await until(open + MIC_LEAD + 6.0);
    await click(220, 646, 'stopTap');
    const stopAt = now();
    const fin = await waitApi('intent', stopAt - 3, (a) => a.req.includes('"final":true'));
    mark('cookUnderstood', { detected: fin.detected });
    const sug = await waitApi('suggestions', stopAt);
    mark('picksShown', { at: sug.t });
    await sleep(8000);
    await click(142, 645, 'viewRecipe');
    await sleep(4500);
    mark('recipeReady');
    await scroll(900, 6, 'scrollRecipe');
    await sleep(500);
    await click(220, 808, 'havingThis');
    await sleep(4000);

    // Dine out by typing.
    await click(220, 260, 'craving2');
    await sleep(1000);
    await click(242, 763, 'typeInstead');
    await sleep(1000);
    await click(220, 625, 'textClick');
    await sleep(200);
    const typeStart = now();
    await typeText('I am going out for dinner', 'typing');
    const chips = await waitApi('intent', typeStart, (a) => a.detected && a.detected.method === 'dine' && a.detected.mealType);
    mark('chipsShown', { at: chips.t });
    await until(chips.t + 2.0);
    await click(220, 709, 'continue');
    const contAt = now();
    const fin2 = await waitApi('intent', contAt - 1, (a) => a.req.includes('"final":true'));
    mark('flavourShown', { at: fin2.t, detected: fin2.detected });
    await until(fin2.t + 1.5);
    await click(130, 278, 'spicy');
    await sleep(800);
    await click(220, 765, 'next');
    await sleep(1200);
    await click(130, 286, 'casual');
    const casualAt = now();
    const sug2 = await waitApi('suggestions', casualAt);
    mark('placesShown', { at: sug2.t });
    await sleep(10000);
    await click(142, 549, 'viewMenu');
    await sleep(5000);
    mark('menuReady');
    await scroll(600, 5, 'scrollMenu');
    await sleep(500);
    await click(220, 808, 'letsGo');
    await sleep(3000);

    // The meal log on Me, then Community.
    await click(367, 815, 'meTab');
    await sleep(4000);
    mark('meReady');
    await click(171, 815, 'communityTab');
    await sleep(3000);
    mark('communityReady');
    await scroll(500, 3, 'scrollCommunity');
    await sleep(2500);
  } else if (TAKE === 'C') {
    // Onboarding by typing, off camera; then ordering in by typing.
    await click(220, 760, 'getStarted');
    await sleep(2500);
    await click(396, 121, 'keyboard');
    await sleep(1500);
    await click(220, 650, 'onbField');
    await sleep(500);
    const typed = now();
    await page.keyboard.type(ONBOARDING, { delay: 20 });
    await sleep(2500);
    await click(220, 750, 'onbContinue');
    await waitApi('intent', typed, (a) => a.req.includes('"final":true'));
    await sleep(6000);
    await click(220, 754, 'startEating');
    await sleep(5000);
    mark('homeReady');
    await sleep(1500);
    await click(220, 260, 'craving');
    await sleep(1000);
    await click(242, 763, 'typeInstead');
    await sleep(1000);
    await click(220, 625, 'textClick');
    await sleep(200);
    const typeStart = now();
    await typeText('Order in a spicy dinner, any cuisine', 'typing');
    const chips = await waitApi('intent', typeStart, (a) => a.detected && a.detected.method === 'order' && a.detected.mealType && a.detected.cuisine && a.detected.flavours);
    mark('chipsShown', { at: chips.t });
    await until(chips.t + 1.5);
    await click(220, 709, 'continue');
    const contAt = now();
    const fin = await waitApi('intent', contAt - 1, (a) => a.req.includes('"final":true'));
    mark('orderUnderstood', { at: fin.t, detected: fin.detected });
    const sug = await waitApi('suggestions', contAt);
    mark('picksShown', { at: sug.t });
    await sleep(7000);
    // "Order on Swiggy" opens a new tab; y 572 is inside the button whether or not the dish name wraps.
    const tab = ctx.waitForEvent('page', { timeout: 8000 }).catch(() => null);
    await click(143, 572, 'swiggy');
    const popup = await tab;
    if (popup) {
      await popup.waitForURL(/swiggy/, { timeout: 6000 }).catch(() => {});
      mark('swiggyTab', { url: popup.url() });
      await popup.close().catch(() => {});
    } else mark('NO SWIGGY TAB');
    await sleep(3500);
  } else {
    // Onboarding by typing, off camera.
    await click(220, 760, 'getStarted');
    await sleep(2500);
    await click(396, 121, 'keyboard');
    await sleep(1500);
    await click(220, 650, 'onbField');
    await sleep(500);
    const typed = now();
    await page.keyboard.type(ONBOARDING, { delay: 20 });
    await sleep(2500);
    await click(220, 750, 'onbContinue');
    await waitApi('intent', typed, (a) => a.req.includes('"final":true'));
    await sleep(6000);
    await click(220, 754, 'startEating');
    await sleep(5000);
    mark('homeReady');

    // Scene 3: cook by voice.
    await click(220, 260, 'craving1');
    await sleep(1500);
    const tap = now();
    await click(220, 646, 'micTap');
    const open = await micOpen(tap);
    mark('micOpen', { at: open, speech: open + MIC_LEAD });
    await until(open + MIC_LEAD + 6.0);
    await click(220, 646, 'stopTap');
    const stopAt = now();
    const fin = await waitApi('intent', stopAt - 3, (a) => a.req.includes('"final":true'));
    mark('cookUnderstood', { detected: fin.detected });
    const sug = await waitApi('suggestions', stopAt);
    mark('picksShown', { at: sug.t });
    await sleep(7000);
    await click(138, 586, 'regular');
    await sleep(2500);
    await click(293, 586, 'healthy');
    await sleep(2000);
    await click(142, 645, 'viewRecipe');
    await sleep(4500);
    mark('recipeReady');
    await scroll(900, 6, 'scrollRecipe');
    await sleep(500);
    await click(220, 808, 'havingThis');
    await sleep(5000);

    // Scene 4: dine out by typing.
    await click(220, 260, 'craving2');
    await sleep(1000);
    await click(242, 763, 'typeInstead');
    await sleep(1000);
    await click(220, 625, 'textClick');
    await sleep(200);
    const typeStart = now();
    await typeText('I am going out for dinner', 'typing');
    const chips = await waitApi('intent', typeStart, (a) => a.detected && a.detected.method === 'dine' && a.detected.mealType);
    mark('chipsShown', { at: chips.t });
    await until(chips.t + 2.0);
    await click(220, 709, 'continue');
    const contAt = now();
    const fin2 = await waitApi('intent', contAt - 1, (a) => a.req.includes('"final":true'));
    mark('flavourShown', { at: fin2.t, detected: fin2.detected });
    await until(fin2.t + 1.5);
    await click(130, 278, 'spicy');
    await sleep(800);
    await click(220, 765, 'next');
    await sleep(1200);
    await click(130, 286, 'casual');
    const casualAt = now();
    const sug2 = await waitApi('suggestions', casualAt);
    mark('placesShown', { at: sug2.t });
    await sleep(10000);
    await click(142, 549, 'viewMenu');
    await sleep(5000);
    mark('menuReady');
    await scroll(600, 5, 'scrollMenu');
    await sleep(500);
    await click(220, 808, 'letsGo');
    await sleep(3500);
  }
  mark('takeEnd');
} catch (e) {
  mark('ERROR ' + e.message);
  await page.screenshot({ path: `${OUT}/error.png` });
}

await cdp.send('Page.stopScreencast');
await sleep(300);
writeFileSync(`${OUT}/log.json`, JSON.stringify(log, null, 1));
const span = log.frames.length ? log.frames.at(-1).t - log.frames[0].t : 0;
console.log(`frames: ${log.frames.length} over ${span.toFixed(1)} s`);
await browser.close();
