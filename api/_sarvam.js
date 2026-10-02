// Shared Sarvam chat helper. Files prefixed with `_` are not exposed as Vercel functions.
const SARVAM_URL = 'https://api.sarvam.ai/v1/chat/completions';
export const SARVAM_MODEL = 'sarvam-105b';

export async function sarvamChat(opts) {
  try {
    return await sarvamChatOnce(opts);
  } catch (err) {
    if (!err.rateLimited) throw err;
    await new Promise((r) => setTimeout(r, 700 + Math.random() * 600));
    return sarvamChatOnce(opts);
  }
}

async function sarvamChatOnce({ system, user, maxTokens = 800, temperature = 0.3, timeoutMs = 25000 }) {
  const apiKey = process.env.SARVAM_API_KEY;
  if (!apiKey) throw new Error('SARVAM_API_KEY not configured');

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(SARVAM_URL, {
      method: 'POST',
      signal: controller.signal,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify({
        model: SARVAM_MODEL,
        messages: [
          ...(system ? [{ role: 'system', content: system }] : []),
          { role: 'user', content: user },
        ],
        max_tokens: maxTokens,
        temperature,
        // sarvam-105b reasons by default; off keeps structured calls fast and
        // stops reasoning from consuming the whole token budget.
        reasoning_effort: null,
      }),
    });
    if (!res.ok) {
      const err = new Error(`Sarvam ${res.status}: ${(await res.text()).slice(0, 300)}`);
      err.rateLimited = res.status === 429;
      throw err;
    }
    const data = await res.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) throw new Error(`Sarvam returned no content (finish_reason=${data.choices?.[0]?.finish_reason})`);
    return content;
  } finally {
    clearTimeout(timer);
  }
}

// Pulls the first JSON object/array out of an LLM reply (tolerates ```json fences and chatter).
export function extractJson(text) {
  const cleaned = text.replace(/```(?:json)?/gi, '').trim();
  const start = cleaned.search(/[[{]/);
  if (start === -1) throw new Error('No JSON found in LLM response');
  const close = cleaned[start] === '{' ? '}' : ']';
  const end = cleaned.lastIndexOf(close);
  if (end <= start) throw new Error('Unterminated JSON in LLM response');
  return JSON.parse(cleaned.slice(start, end + 1));
}

// For JSON arrays of objects: if the whole reply doesn't parse (e.g. one malformed
// item), salvage every top-level object that does parse instead of failing outright.
export function extractJsonItems(text) {
  try {
    const whole = extractJson(text);
    if (Array.isArray(whole)) return whole;
  } catch {
    // fall through to per-object salvage
  }
  const items = [];
  let depth = 0;
  let start = -1;
  let inString = false;
  let escaped = false;
  for (let i = Math.max(0, text.indexOf('[')); i < text.length; i++) {
    const c = text[i];
    if (inString) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') inString = false;
      continue;
    }
    if (c === '"') inString = true;
    else if (c === '{') {
      if (depth === 0) start = i;
      depth++;
    } else if (c === '}' && depth > 0) {
      depth--;
      if (depth === 0 && start >= 0) {
        try { items.push(JSON.parse(text.slice(start, i + 1))); } catch { /* skip malformed item */ }
        start = -1;
      }
    }
  }
  return items;
}

export function str(v, max = 300) {
  return typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : undefined;
}

export function strList(v, maxItems = 30, maxLen = 200) {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x, maxLen)).filter(Boolean).slice(0, maxItems);
}

export function num(v, fallback = 0) {
  const n = typeof v === 'number' ? v : parseFloat(v);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

export function readBody(req) {
  return req.body && typeof req.body === 'object' ? req.body : {};
}
