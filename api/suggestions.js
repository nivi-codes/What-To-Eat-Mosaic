// POST /api/suggestions
// LLM meal suggestions, filtered server-side by the user's diet rules, with real dish
// photos from Wikimedia. Cook suggestions are lightweight (recipe comes from
// /api/recipe on demand); dine suggestions are restaurants with no nutrition.
import { sarvamChat, extractJsonItems, str, strList, num, readBody } from './_sarvam.js';
import { dietClass, dietRule, isAllowed, dishDiet, violatesDiet, DISH_DIET_FIELD } from './_diet.js';
import { findDishImage } from './_images.js';

const U = (id) => `https://images.unsplash.com/${id}?w=400`;

const MOCK_SUGGESTIONS = {
  cook: [
    { id: 's1', title: 'Dal Tadka with Rice', subtitle: '30 min · Veg · North Indian', diet: 'vegetarian', imageQuery: 'Dal tadka', nutrition: { calories: 420, proteinG: 20, carbsG: 70, fatG: 8, fiberG: 10 }, healthyNutrition: { calories: 320, proteinG: 21, carbsG: 58, fatG: 4, fiberG: 12 }, hasHealthyVersion: true, healthHighlights: ['High in protein', 'Good source of fibre'], tags: ['veg', 'comfort'] },
    { id: 's2', title: 'Paneer Butter Masala', subtitle: '35 min · Veg · North Indian', diet: 'vegetarian', imageQuery: 'Paneer butter masala', nutrition: { calories: 480, proteinG: 22, carbsG: 28, fatG: 32, fiberG: 4 }, hasHealthyVersion: false, healthHighlights: ['High in protein', 'Calcium-rich'], tags: ['veg', 'rich'] },
    { id: 's3', title: 'Chana Masala', subtitle: '30 min · Vegan · Punjabi', diet: 'vegan', imageQuery: 'Chana masala', nutrition: { calories: 360, proteinG: 15, carbsG: 52, fatG: 9, fiberG: 13 }, hasHealthyVersion: false, healthHighlights: ['High in fibre', 'Plant protein'], tags: ['vegan', 'spicy'] },
    { id: 's10', title: 'Vegetable Poha', subtitle: '15 min · Vegan · Maharashtrian', diet: 'vegan', imageQuery: 'Poha', nutrition: { calories: 270, proteinG: 6, carbsG: 48, fatG: 6, fiberG: 3 }, hasHealthyVersion: false, healthHighlights: ['Light', 'Quick'], tags: ['vegan', 'breakfast'] },
    { id: 's14', title: 'Veg Hakka Noodles', subtitle: '25 min · Vegan · Indo-Chinese', diet: 'vegan', imageQuery: 'Hakka noodles', nutrition: { calories: 380, proteinG: 10, carbsG: 62, fatG: 12, fiberG: 4 }, hasHealthyVersion: false, healthHighlights: ['Veggie-loaded', 'Quick'], tags: ['vegan', 'chinese'] },
    { id: 's16', title: 'Egg Fried Rice', subtitle: '20 min · Egg · Indo-Chinese', diet: 'eggetarian', imageQuery: 'Egg fried rice', nutrition: { calories: 420, proteinG: 16, carbsG: 58, fatG: 14, fiberG: 3 }, hasHealthyVersion: false, healthHighlights: ['Protein from eggs', 'Quick'], tags: ['egg', 'quick'] },
    { id: 's17', title: 'Chicken Curry', subtitle: '40 min · Non-veg · North Indian', diet: 'non-vegetarian', imageQuery: 'Chicken curry', nutrition: { calories: 450, proteinG: 34, carbsG: 12, fatG: 28, fiberG: 3 }, hasHealthyVersion: false, healthHighlights: ['High in protein'], tags: ['non-veg', 'spicy'] },
  ],
  order: [
    { id: 's4', title: 'Chicken Biryani', subtitle: 'Behrouz Biryani · 30 min · ₹320', diet: 'non-vegetarian', imageQuery: 'Chicken biryani', nutrition: { calories: 580, proteinG: 36, carbsG: 68, fatG: 18, fiberG: 3 }, healthHighlights: ['High in protein'], tags: ['non-veg', 'spicy'] },
    { id: 's5', title: 'Margherita Pizza', subtitle: "Domino's · 25 min · ₹249", diet: 'vegetarian', imageQuery: 'Pizza Margherita', nutrition: { calories: 520, proteinG: 18, carbsG: 72, fatG: 18, fiberG: 4 }, healthHighlights: ['Calcium-rich'], tags: ['veg', 'cheesy'] },
    { id: 's21', title: 'South Indian Veg Thali', subtitle: 'Saravana Bhavan · 30 min · ₹280', diet: 'vegetarian', imageQuery: 'South Indian thali', nutrition: { calories: 480, proteinG: 16, carbsG: 72, fatG: 14, fiberG: 8 }, healthHighlights: ['Balanced meal'], tags: ['veg', 'south-indian'] },
    { id: 's23', title: 'Rajma Chawal', subtitle: 'Punjabi Rasoi · 30 min · ₹220', diet: 'vegan', imageQuery: 'Rajma', nutrition: { calories: 450, proteinG: 17, carbsG: 78, fatG: 7, fiberG: 12 }, healthHighlights: ['Plant protein', 'Fibre-rich'], tags: ['vegan', 'comfort'] },
    { id: 's24', title: 'Veg Hakka Noodles', subtitle: 'Wow! China · 35 min · ₹210', diet: 'vegan', imageQuery: 'Hakka noodles', nutrition: { calories: 420, proteinG: 10, carbsG: 66, fatG: 13, fiberG: 4 }, healthHighlights: ['Veggie-loaded'], tags: ['vegan', 'chinese'] },
    { id: 's25', title: 'Masala Dosa', subtitle: 'MTR · 25 min · ₹150', diet: 'vegan', imageQuery: 'Masala dosa', nutrition: { calories: 330, proteinG: 8, carbsG: 55, fatG: 9, fiberG: 4 }, healthHighlights: ['Fermented', 'Light'], tags: ['vegan', 'south-indian'] },
  ],
  dine: [
    { id: 's7', title: 'Saravana Bhavan', subtitle: 'South Indian · Casual · ₹₹', imageQuery: 'Masala dosa', healthHighlights: ['Pure veg', 'Quick service'], tags: ['South Indian'] },
    { id: 's8', title: 'Punjabi by Nature', subtitle: 'North Indian · Lively · ₹₹₹', imageQuery: 'Dal makhani', healthHighlights: ['Great for groups'], tags: ['North Indian'] },
    { id: 's9', title: 'Third Wave Coffee', subtitle: 'Café · Cosy · ₹₹', imageQuery: 'Cappuccino', healthHighlights: ['Good coffee', 'Work-friendly'], tags: ['Café'] },
    { id: 's22', title: 'Mainland China', subtitle: 'Chinese · Fine dine · ₹₹₹', imageQuery: 'Dim sum', healthHighlights: ['Special occasions'], tags: ['Chinese'] },
  ],
};

// Fallback photos when Wikimedia has no match; each tagged with what it shows.
const FALLBACK_IMAGES = [
  [/biryani|mughlai/i, U('photo-1563379091339-03b21ab4a4f8'), 'non-vegetarian'],
  [/dosa|idli|uttapam/i, U('photo-1668236543090-82eba5ee5976'), 'vegetarian'],
  [/noodle|hakka|chow/i, U('photo-1569718212165-3a8278d5f624'), 'non-vegetarian'],
  [/\brice\b|pulao/i, U('photo-1603133872878-684f208fb84b'), 'eggetarian'],
  [/pizza|pasta/i, U('photo-1565299624946-b28f40a0ae38'), 'vegetarian'],
  [/paneer|makhani|korma/i, U('photo-1631452180519-c014fe946bc7'), 'vegetarian'],
  [/chole|chana|rajma/i, U('photo-1625220194771-7ebdea0b70b9'), 'vegetarian'],
  [/wrap|roll|sandwich/i, U('photo-1626700051175-6818013e1d4f'), 'vegetarian'],
];
const DINE_IMAGES = [
  'photo-1517248135467-4c7edcad34c4', 'photo-1414235077428-338989a2e8c0', 'photo-1555396273-367ea4eb4db5',
  'photo-1552566626-52f8b828add9', 'photo-1559339352-11d035aa65de', 'photo-1590846406792-0adc7f938f1d',
].map(U);

// Empty string -> the app shows a neutral placeholder, which beats a photo of a different dish.
async function imageFor(item, method, diet, index) {
  const found = (await findDishImage(item.imageQuery, diet)) ||
    (item.imageQuery !== item.title ? await findDishImage(item.title, diet) : null);
  if (found) return found;
  if (method === 'dine') return DINE_IMAGES[index % DINE_IMAGES.length];
  const ok = (label) => diet === 'non-vegetarian' || label === 'vegan' || label === 'vegetarian' || (diet === 'eggetarian' && label === 'eggetarian');
  const hit = FALLBACK_IMAGES.find(([re, , label]) => re.test(item.title) && ok(label));
  return hit ? hit[1] : '';
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function nutrition(v) {
  if (!v || typeof v !== 'object' || !num(v.calories)) return null;
  return { calories: Math.round(num(v.calories)), proteinG: num(v.proteinG), carbsG: num(v.carbsG), fatG: num(v.fatG), fiberG: num(v.fiberG) };
}

const IMAGE_QUERY_FIELD = `"imageQuery": the dish's common name in 1-3 words, no "with ..." details (e.g. "Egg fried rice", "Vegetable biryani", "Masala dosa", "Cabbage thoran")`;

function buildPrompt(p) {
  const avoid = strList(p.preferences?.avoidances).filter((a) => a.toLowerCase() !== 'none');
  const context = [
    p.freeInput && `In their words: "${p.freeInput}"`,
    p.mealType && `Meal: ${p.mealType}`,
    p.flavour && `Flavour: ${p.flavour}`,
    p.cuisinePreference && `Cuisine: ${p.cuisinePreference}`,
    p.method === 'cook' && p.ingredients.length && `Ingredients they have: ${p.ingredients.join(', ')} (only use ones their diet allows)`,
    p.method === 'cook' && p.cookTime && `Time available: ${p.cookTime}`,
    p.method === 'dine' && p.dineVibe && `Vibe: ${p.dineVibe}`,
    `Diet rule: ${dietRule(p.diet)}`,
    avoid.length && `Avoid: ${avoid.join(', ')}`,
  ].filter(Boolean).join('\n');

  const shapes = {
    cook: `Dishes they can cook at home NOW, mainly from the ingredients they have (basic spices/oil/onion assumed).
Each item: {"title": "dish name", "subtitle": "<total minutes> min · <Vegan/Veg/Egg/Non-veg> · <cuisine>", "cuisine": "...", ${DISH_DIET_FIELD}, ${IMAGE_QUERY_FIELD}, "nutrition": {"calories": n, "proteinG": n, "carbsG": n, "fatG": n, "fiberG": n}, "hasHealthyVersion": bool, "healthyNutrition": {...} or null, "healthHighlights": ["max 3 short"], "tags": ["max 4"]}`,
    order: `Dishes to order for delivery from popular Indian delivery restaurants.
Each item: {"title": "dish name", "subtitle": "<restaurant> · <minutes> min · ₹<price>", "cuisine": "...", ${DISH_DIET_FIELD}, ${IMAGE_QUERY_FIELD}, "nutrition": {"calories": n, "proteinG": n, "carbsG": n, "fatG": n, "fiberG": n}, "healthHighlights": ["max 3 short"], "tags": ["max 4"]}`,
    dine: `Restaurants/cafés to go out to in an Indian metro city (well-known chains or popular styles of place) that have plenty of dishes fitting the diet rule.
Each item: {"title": "restaurant name", "subtitle": "<cuisine> · <vibe> · <₹ to ₹₹₹₹>", "cuisine": "...", "imageQuery": "the signature dish this place is known for that fits the diet rule, e.g. Masala dosa", "healthHighlights": ["max 3 short things it's known for, e.g. 'Great for groups'"], "tags": ["max 4"]}. No nutrition.`,
  };

  const count = p.method === 'dine' ? 3 : 5;
  return `You recommend food for urban Indians aged 18-35. Suggest exactly ${count} DIFFERENT options (vary cuisine and effort) that fit:
${p.method === 'dine' ? '' : 'Suggest real, well-known dishes people would recognise by name (e.g. "Cabbage thoran", "Vegetable pulao", "Egg bhurji") — not invented fusion names like "Cabbage Rice Cutlet".\n'}
${context}

${shapes[p.method]}
Reply with ONLY a JSON array of ${count} items, no markdown.`;
}

async function llmSuggestions(p) {
  const reply = await sarvamChat({ user: buildPrompt(p), maxTokens: 2200, temperature: 0.8, timeoutMs: 30000 });
  const items = extractJsonItems(reply);
  if (!items.length) throw new Error('No parseable suggestions in LLM reply');
  return items
    .map((s) => ({
      title: str(s.title, 100),
      subtitle: str(s.subtitle, 120) || str(s.cuisine, 40) || '',
      diet: dishDiet(s.diet),
      imageQuery: str(s.imageQuery, 80),
      nutrition: nutrition(s.nutrition),
      healthyNutrition: nutrition(s.healthyNutrition),
      hasHealthyVersion: Boolean(s.hasHealthyVersion),
      healthHighlights: strList(s.healthHighlights, 3, 40),
      tags: strList(s.tags, 4, 30),
    }))
    .filter((s) => s.title && (p.method === 'dine' ||
      (s.nutrition && isAllowed(s.diet, p.diet) && !violatesDiet(`${s.title} ${s.subtitle}`, p.diet))));
}

async function finalize(items, p) {
  const stamp = Date.now();
  return Promise.all(items.slice(0, 3).map(async (s, i) => {
    const id = s.id ? `mock_${s.id}_${stamp}` : `llm_${stamp}_${i}`;
    return {
      id,
      recipeId: id,
      title: s.title,
      subtitle: s.subtitle,
      path: p.method,
      diet: p.method === 'dine' ? null : s.diet,
      imageUrl: await imageFor(s, p.method, p.method === 'dine' ? p.diet : s.diet, i),
      ...(p.method !== 'dine' && s.nutrition ? { nutrition: s.nutrition } : {}),
      healthyNutrition: p.method === 'cook' && s.hasHealthyVersion && s.healthyNutrition ? s.healthyNutrition : null,
      hasHealthyVersion: Boolean(p.method === 'cook' && s.hasHealthyVersion && s.healthyNutrition),
      healthHighlights: s.healthHighlights || [],
      tags: s.tags || [],
    };
  }));
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const b = readBody(req);
  const method = ['cook', 'order', 'dine'].includes(b.method) ? b.method : 'cook';
  const preferences = b.preferences && typeof b.preferences === 'object' ? b.preferences : {};
  const p = {
    method,
    diet: dietClass(preferences.dietaryType),
    mealType: str(b.mealType, 20),
    flavour: str(b.flavour, 80),
    ingredients: strList(b.ingredients, 25, 60),
    cookTime: str(b.cookTime, 20),
    cuisinePreference: str(b.cuisinePreference, 40),
    dineVibe: str(b.dineVibe, 40),
    freeInput: str(b.freeInput, 500),
    preferences,
  };

  // The prompt asks for diet-appropriate dishes, but compliance is enforced here
  // from each dish's own diet label; retry once if too few survive.
  let picked = [];
  for (let attempt = 0; attempt < 2 && picked.length < 3; attempt++) {
    try {
      const fresh = await llmSuggestions(p);
      picked = [...picked, ...fresh.filter((s) => !picked.some((x) => x.title.toLowerCase() === s.title.toLowerCase()))];
    } catch (err) {
      console.error(`Suggestions LLM attempt ${attempt + 1} failed:`, err.message);
    }
  }

  if (picked.length < 3) {
    const pool = shuffle([...(MOCK_SUGGESTIONS[method] || MOCK_SUGGESTIONS.cook)])
      .filter((s) => method === 'dine' || isAllowed(s.diet, p.diet));
    picked = [...picked, ...pool.filter((s) => !picked.some((x) => x.title === s.title))];
  }
  return res.status(200).json(await finalize(picked, p));
}
