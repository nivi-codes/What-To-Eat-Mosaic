// Real photo for a dish via Wikimedia (CORS-enabled, no API key).
// The LLM supplies a specific dish name ("Egg fried rice"); we search Wikimedia
// Commons for a photo whose filename names that dish, rejecting photos whose
// filename conflicts with the dish's diet (e.g. chicken in a veg dish's photo).
const UA = 'WhatToEat/1.0 (https://mosaic-seven-henna.vercel.app)';
const cache = new Map();

const MEAT = /chicken|mutton|beef|pork|lamb|goat|fish|prawn|shrimp|crab|lobster|seafood|meat|keema|bacon|ham\b|sausage|ilish|tuna|salmon|squid|duck|turkey|kebab/i;
const EGG = /\begg|anda\b|omelet/i;
const DAIRY = /paneer|cheese|butter|ghee|cream|curd|yogurt|yoghurt|milk|malai|raita|lassi/i;
const NOT_PHOTO = /\.svg|logo|icon|symbol|flag|map|diagram|menu|sign|board|(^|[^a-z])(lane|road|shop|storefront|exterior|facade|building)([^a-z]|$)/i;
const STOP = new Set(['and', 'with', 'the', 'style', 'homemade', 'home', 'indian', 'quick', 'spicy', 'easy', 'simple', 'special']);

function conflictsWithDiet(name, diet) {
  if (diet === 'non-vegetarian' || !diet) return false;
  if (MEAT.test(name)) return true;
  if ((diet === 'vegetarian' || diet === 'vegan') && EGG.test(name)) return true;
  if (diet === 'vegan' && DAIRY.test(name)) return true;
  return false;
}

// Whole-word match (singular/plural tolerant): every word of the dish name must be
// a word in the filename. Substring matching let "based" match "bas…" in unrelated files.
const singular = (w) => w.replace(/(es|s)$/, '');
function namesDish(fileTitle, query) {
  const tokens = new Set(fileTitle.toLowerCase().split(/[^a-z]+/).filter(Boolean).map(singular));
  const words = query.toLowerCase().split(/[^a-z]+/).filter((w) => w.length >= 3 && !STOP.has(w));
  return words.length > 0 && words.every((w) => tokens.has(singular(w)));
}

async function api(host, params) {
  const url = `https://${host}/w/api.php?` + new URLSearchParams({ action: 'query', format: 'json', formatversion: '2', ...params });
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 3000);
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, signal: controller.signal });
    if (!res.ok) throw new Error(`Wikimedia ${res.status}`); // transient: don't cache as "no image"
    const data = await res.json();
    return (data.query?.pages || []).sort((a, b) => (a.index ?? 0) - (b.index ?? 0));
  } finally {
    clearTimeout(timer);
  }
}

async function fromCommons(query, diet) {
  const files = await api('commons.wikimedia.org', {
    generator: 'search',
    gsrnamespace: '6',
    gsrsearch: `${query} filetype:bitmap`,
    gsrlimit: '15',
    prop: 'imageinfo',
    iiprop: 'url',
    iiurlwidth: '640',
  });
  const hit = files.find((f) =>
    f.imageinfo?.[0]?.thumburl && !NOT_PHOTO.test(f.title) && namesDish(f.title, query) && !conflictsWithDiet(f.title, diet));
  return hit ? hit.imageinfo[0].thumburl.split('?')[0] : null;
}

async function fromWikipediaArticle(query, diet) {
  const pages = await api('en.wikipedia.org', {
    titles: query, redirects: '1', prop: 'pageimages', piprop: 'thumbnail', pithumbsize: '640',
  });
  const src = pages.find((p) => !p.missing)?.thumbnail?.source;
  if (!src || NOT_PHOTO.test(src) || conflictsWithDiet(decodeURIComponent(src), diet)) return null;
  return src.split('?')[0];
}

// Too vague on their own to show the right dish.
const VAGUE = new Set(['roll', 'rolls', 'bowl', 'plate', 'platter', 'mix', 'combo', 'delight', 'special', 'fry', 'masala', 'curry', 'stuffed', 'style', 'salad', 'wrap', 'box', 'meal']);

// "Cabbage egg pulao with raita" -> ["Cabbage egg pulao with raita", "Cabbage egg pulao", "egg pulao", "pulao"]
function candidates(q) {
  const base = q.replace(/\s+(with|and|in|on|served|topped|plus)\b.*$/i, '').replace(/[-–]/g, ' ').trim();
  const words = base.split(/\s+/).filter(Boolean);
  const out = [q, base];
  // Dropping words from "quinoa power bowl" leaves "power bowl" (-> Super Bowl photos);
  // only shorten names whose head noun identifies the dish.
  if (VAGUE.has((words[words.length - 1] || '').toLowerCase())) return [...new Set(out)];
  for (let i = 1; i < words.length; i++) {
    const rest = words.slice(i);
    if (rest.length === 1 && (VAGUE.has(rest[0].toLowerCase()) || rest[0].length < 4)) continue;
    out.push(rest.join(' '));
  }
  return [...new Set(out.filter((s) => s.length >= 3))];
}

/** @param diet the dish's own diet label: vegan | vegetarian | eggetarian | non-vegetarian */
export async function findDishImage(query, diet) {
  const q = typeof query === 'string' ? query.trim().slice(0, 80) : '';
  if (!q) return null;
  const key = `${q.toLowerCase()}|${diet || ''}`;
  if (cache.has(key)) return cache.get(key);

  // Multi-word names ("Egg fried rice") are specific enough to match Commons
  // filenames; a single word ("Pulao") also matches unrelated files (a bell
  // sculpture), so single words only use the dish's Wikipedia article photo.
  let src = null;
  try {
    for (const c of candidates(q)) {
      const multiWord = c.split(/\s+/).length >= 2;
      src = (multiWord && (await fromCommons(c, diet))) || (await fromWikipediaArticle(c, diet));
      if (src) break;
    }
  } catch (err) {
    console.error('Image lookup failed:', q, err.message);
    return null; // network/rate-limit error: not cached, so a later request can retry
  }
  cache.set(key, src);
  return src;
}
