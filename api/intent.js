// POST /api/intent  { flowType: 'eat_flow' | 'onboarding' | 'ingredients', text }
// -> { detected: {...} }  — LLM intent understanding, clamped to the values the app accepts.
import { sarvamChat, extractJson, str, strList, readBody } from './_sarvam.js';

const FLAVOURS = ['Spicy', 'Light', 'Comforting', 'Sweet', 'Fresh', 'Rich', 'Tangy', 'Smoky'];

const EAT = {
  mealType: ['breakfast', 'lunch', 'snack', 'dinner'],
  method: ['cook', 'order', 'dine'],
  cookTime: ['15 minutes', '30 minutes', '45 minutes', 'Any time'],
  vibe: ['casual', 'quick bite', 'something special'],
};

const ONBOARDING = {
  dietary: ['Vegetarian', 'Vegan', 'Eggetarian', 'Non-vegetarian'],
  cuisines: ['North Indian', 'South Indian', 'Street Food', 'Chinese', 'Italian', 'Continental', 'Mughlai', 'Gujarati'],
  avoidances: ['Dairy', 'Gluten', 'Nuts', 'None'],
  healthy: ['Healthy first', 'Regular first', 'Show both', 'No preference'],
};

const COMMON_RULES = `The input is casual speech or typing from an urban Indian user. It may be a voice transcript without punctuation, Hinglish, informal, or misspelled. Understand the MEANING, not exact words — people say the same thing many ways.
Reply with ONLY a JSON object, no markdown, no explanation. Each key you include maps to {"value": ..., "evidence": "..."} where evidence is the user's EXACT words (copied verbatim from their text) that express that value.
Consider EVERY key below one by one. The same words can be the evidence for more than one key — one phrase often answers several questions at once.
Include a key ONLY if you can quote such words. Never fill in defaults or guesses, and never derive one key from another (a cuisine does not imply a flavour or a meal; a time of day does not imply a method). If nothing is expressed, return {}.`;

const PROMPTS = {
  eat_flow: `${COMMON_RULES}
The user is deciding what to eat right now. Keys:
- "method": "cook" (make it themselves at home), "order" (delivery/takeaway, Swiggy, Zomato, "get something delivered"), "dine" (going out, eating out, at a restaurant/cafe/dhaba, "heading out to eat").
- "mealType": one of ${EAT.mealType.join('|')}. ONLY when they name a meal or a time of day (tonight/late night -> dinner, this morning -> breakfast, evening chai-time bite -> snack). Hunger, cravings or portion size alone are NOT a meal type.
- "flavours": array from [${FLAVOURS.join(', ')}]. Map synonyms: "with a kick"/teekha/chatpata -> Spicy; heavy/indulgent/creamy -> Rich; ghar ka khana/homely/soul food -> Comforting; healthy-ish/not heavy -> Light.
- "ingredients": array of food items they have available to cook with (short names, no quantities, skip salt/oil/water/basic spices).
- "cookTime": one of ${EAT.cookTime.join('|')} — only if they mention how much time they have or urgency ("quick"/"in a hurry" -> "15 minutes"; "no rush" -> "Any time").
- "cuisine": a cuisine name if mentioned or clearly implied (e.g. "Chinese", "South Indian", "Italian"), or "Any" if they say any cuisine is fine.
- "vibe": one of ${EAT.vibe.join('|')} — only for eating out (date/celebration/anniversary -> "something special"; grabbing something fast -> "quick bite"; chilling with friends -> "casual").
Examples:
"we're stepping out to eat tonight" -> {"mealType":{"value":"dinner","evidence":"tonight"},"method":{"value":"dine","evidence":"stepping out to eat"}}
"grabbing breakfast at a cafe" -> {"mealType":{"value":"breakfast","evidence":"grabbing breakfast at a cafe"},"method":{"value":"dine","evidence":"grabbing breakfast at a cafe"}}
"order karte hain, biryani mood" -> {"method":{"value":"order","evidence":"order karte hain"},"cuisine":{"value":"Biryani","evidence":"biryani"}}
"something filling for breakfast" -> {"mealType":{"value":"breakfast","evidence":"breakfast"}}
"I've got potatoes and peas" -> {"ingredients":{"value":["Potatoes","Peas"],"evidence":"potatoes and peas"}}
"craving something cosy and chatpata" -> {"flavours":{"value":["Comforting","Spicy"],"evidence":"cosy and chatpata"}}`,

  onboarding: `${COMMON_RULES}
The user is describing their everyday food preferences. Keys:
- "dietary": one of ${ONBOARDING.dietary.join('|')} ("I eat everything"/"chicken is my fav" -> Non-vegetarian; "veg but I eat eggs" -> Eggetarian; "no animal products" -> Vegan).
- "cuisines": array from [${ONBOARDING.cuisines.join(', ')}]. Map dishes to cuisines: dosa/idli -> South Indian; chaat/pav bhaji/vada pav -> Street Food; biryani/kebabs -> Mughlai; pasta/pizza -> Italian; noodles/manchurian -> Chinese; dhokla/thepla -> Gujarati; butter chicken/rajma/paratha -> North Indian.
- "flavours": array from [${FLAVOURS.join(', ')}] (map synonyms as meaning, e.g. teekha -> Spicy).
- "avoidances": array from [${ONBOARDING.avoidances.join(', ')}] for allergies/intolerances/things they avoid ("lactose intolerant" -> Dairy; "celiac" -> Gluten; "allergic to peanuts/cashews" -> Nuts; "no allergies"/"I eat anything" -> ["None"]).
- "healthy": one of ${ONBOARDING.healthy.join('|')} ("trying to eat clean" -> Healthy first; "don't care about calories" -> Regular first; "show me both" -> Show both).
Example: "mostly veg, idli is life, peanuts make me sick" -> {"dietary":{"value":"Vegetarian","evidence":"mostly veg"},"cuisines":{"value":["South Indian"],"evidence":"idli is life"},"avoidances":{"value":["Nuts"],"evidence":"peanuts make me sick"}}`,

  ingredients: `${COMMON_RULES}
The user is listing what they have in the kitchen. Use the single key "ingredients" whose value is an array of food items as short names in Title Case, no quantities. Skip salt, oil, water and basic spices.
Example: "bas thoda rice aur 2 ande" -> {"ingredients":{"value":["Rice","Eggs"],"evidence":"rice aur 2 ande"}}`,
};

function pickOne(v, allowed) {
  if (typeof v !== 'string') return undefined;
  const lower = v.trim().toLowerCase();
  return allowed.find((a) => a.toLowerCase() === lower);
}

function pickMany(v, allowed) {
  if (!Array.isArray(v)) return undefined;
  const out = [...new Set(v.map((x) => pickOne(x, allowed)).filter(Boolean))];
  return out.length ? out : undefined;
}

function titleCase(s) {
  return s.replace(/\b\w/g, (c) => c.toUpperCase());
}

function normalize(s) {
  return s.toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, ' ').replace(/\s+/g, ' ').trim();
}

// Keeps only fields whose evidence really comes from the user's text — the model
// otherwise tends to invent plausible values the user never expressed. Quotes may
// skip words ("get something ... delivered"), so the evidence words must appear in
// the text in order, but not necessarily contiguously.
// Quotes often differ from the input by a plural ("dosa and chaat" for "dosas and
// chaat"), so words are compared without a trailing s / es.
const stem = (w) => (w.length > 3 ? w.replace(/(es|s)$/, '') : w);

function groundedValues(raw, text) {
  const words = normalize(text).split(' ').map(stem);
  const out = {};
  const grounded = (f) => {
    const ev = f && typeof f.evidence === 'string' ? normalize(f.evidence).split(' ').filter(Boolean).map(stem) : [];
    if (!ev.length) return false;
    let j = 0;
    for (const w of words) if (j < ev.length && w === ev[j]) j++;
    return j === ev.length;
  };
  for (const [key, field] of Object.entries(raw || {})) {
    if (Array.isArray(field)) {
      // List fields sometimes come back as per-item [{value, evidence}, ...].
      const values = field.filter((f) => f && typeof f === 'object' && grounded(f)).flatMap((f) => f.value);
      if (values.length) out[key] = values;
    } else if (field && typeof field === 'object' && grounded(field)) {
      out[key] = field.value;
    }
  }
  return out;
}

// The model now and then skips a key even when the words are plain ("... spicy for
// dinner" came back without a meal). A meal named outright is not a guess, so it is
// filled in when exactly one is named; anything implied is still left to the model.
function namedMeal(text) {
  const meals = new Set((normalize(text).match(/\b(breakfast|lunch|dinner|snacks?)\b/g) || []).map((w) => w.replace(/s$/, '')));
  return meals.size === 1 ? [...meals][0] : undefined;
}

function mergeValues(results) {
  const merged = {};
  for (const r of results) {
    for (const [key, value] of Object.entries(r)) {
      if (!(key in merged)) merged[key] = value;
      else if (Array.isArray(merged[key]) && Array.isArray(value)) merged[key] = [...merged[key], ...value];
    }
  }
  return merged;
}

function sanitize(flowType, raw) {
  const d = {};
  const set = (k, v) => { if (v !== undefined && !(Array.isArray(v) && v.length === 0)) d[k] = v; };
  const ingredients = [...new Set(strList(raw.ingredients, 25, 40).map(titleCase))];

  if (flowType === 'eat_flow') {
    set('mealType', pickOne(raw.mealType, EAT.mealType));
    set('method', pickOne(raw.method, EAT.method));
    set('flavours', pickMany(raw.flavours, FLAVOURS));
    set('cuisine', str(raw.cuisine, 40));
    if (d.method !== 'order' && d.method !== 'dine') {
      set('ingredients', ingredients);
      set('cookTime', pickOne(raw.cookTime, EAT.cookTime));
    }
    if (d.method !== 'cook' && d.method !== 'order') set('vibe', pickOne(raw.vibe, EAT.vibe));
    // "any cuisine is fine" answers the cuisine question (the app's own option is "Any").
    if (/^(any|anything|none|no preference|whatever)$/i.test(d.cuisine || '')) d.cuisine = 'Any';
  } else if (flowType === 'onboarding') {
    set('dietary', pickOne(raw.dietary, ONBOARDING.dietary));
    set('cuisines', pickMany(raw.cuisines, ONBOARDING.cuisines));
    set('flavours', pickMany(raw.flavours, FLAVOURS));
    let avoid = pickMany(raw.avoidances, ONBOARDING.avoidances);
    if (avoid && avoid.length > 1) avoid = avoid.filter((a) => a !== 'None');
    set('avoidances', avoid);
    set('healthy', pickOne(raw.healthy, ONBOARDING.healthy));
  } else {
    set('ingredients', ingredients);
  }
  return d;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const body = readBody(req);
  const flowType = body.flowType;
  const text = str(body.text, 2000);
  if (!PROMPTS[flowType]) return res.status(400).json({ error: 'Invalid flowType' });
  if (!text) return res.status(200).json({ detected: {} });

  // Final submits run two independent extractions and merge them: the model
  // intermittently stops after using one phrase for one field ("going out for
  // dinner" -> meal but no method). Every value is still evidence-checked, so
  // merging only recovers what was said. Live previews use one call (rate limits).
  const extractOnce = async () => {
    const reply = await sarvamChat({
      system: PROMPTS[flowType],
      user: text,
      maxTokens: 500,
      temperature: 0.2,
      timeoutMs: 12000,
    });
    return groundedValues(extractJson(reply), text);
  };

  try {
    const attempts = body.final === true ? 2 : 1;
    const settled = await Promise.allSettled(Array.from({ length: attempts }, extractOnce));
    const results = settled.filter((r) => r.status === 'fulfilled').map((r) => r.value);
    if (!results.length) throw settled[0].reason;
    const merged = mergeValues(results);
    if (flowType === 'eat_flow' && !merged.mealType) merged.mealType = namedMeal(text);
    return res.status(200).json({ detected: sanitize(flowType, merged) });
  } catch (err) {
    console.error('Intent extraction failed:', err.message);
    return res.status(502).json({ error: 'Intent extraction failed' });
  }
}
