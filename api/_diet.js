// Diet rules, from least to most permissive:
//   vegan        -> vegan only
//   vegetarian   -> vegetarian or vegan
//   eggetarian   -> eggetarian, vegetarian or vegan
//   non-veg      -> anything (a mix, not only non-veg)
export const DIETS = ['vegan', 'vegetarian', 'eggetarian', 'non-vegetarian'];

const ALLOWED = {
  vegan: ['vegan'],
  vegetarian: ['vegan', 'vegetarian'],
  eggetarian: ['vegan', 'vegetarian', 'eggetarian'],
  'non-vegetarian': DIETS,
};

/** Normalizes stored profile values ("vegetarian", "non-veg", "Non-vegetarian", ...). */
export function dietClass(raw) {
  const s = String(raw || '').toLowerCase();
  if (s.includes('vegan')) return 'vegan';
  if (s.includes('egg')) return 'eggetarian';
  if (s.includes('non')) return 'non-vegetarian';
  if (s.includes('veg')) return 'vegetarian';
  return 'non-vegetarian'; // no restriction recorded
}

export function allowedDiets(cls) {
  return ALLOWED[cls] || DIETS;
}

/** Normalizes an LLM-provided label for a single dish. */
export function dishDiet(label) {
  const s = String(label || '').toLowerCase().trim();
  if (s.startsWith('vegan')) return 'vegan';
  if (s.includes('egg')) return 'eggetarian';
  if (s.includes('non') || /meat|chicken|fish/.test(s)) return 'non-vegetarian';
  if (s.includes('veg')) return 'vegetarian';
  return undefined;
}

export function isAllowed(label, cls) {
  const d = dishDiet(label);
  return Boolean(d) && allowedDiets(cls).includes(d);
}

// Backstop for mislabelled dishes (the model calls e.g. gulab jamun "vegan"):
// reject dishes whose name/ingredients name something the diet forbids.
const MEAT_WORDS = /\b(chicken|mutton|lamb|goat|beef|pork|bacon|ham|fish|prawns?|shrimps?|crab|lobster|squid|seafood|keema|kheema|meat|tuna|salmon|duck|turkey)\b/i;
const EGG_WORDS = /\b(eggs?|anda|omelett?e|bhurji)\b/i;
const DAIRY_WORDS = /\b(paneer|ghee|butter|cream|creamy|malai|makhani|cheese|curd|dahi|yogh?urt|raita|lassi|milk|khoya|khoa|mawa|rabri|rabdi|kheer|kulfi|rasmalai|gulab jamun|shrikhand|honey|chhena|rasgulla|sandesh|barfi|burfi|peda|chai|latte|cappuccino|buttermilk|chaas|chaach|mor|kaapi|filter coffee|cold coffee|milkshake|jigarthanda|basundi|payasam|phirni|firni|falooda|thandai|kalakand|mysore pak)\b/i;
const PLANT_BASED = /\b(coconut|almond|soy|soya|oat|cashew|peanut)\s+(milk|cream|butter|curd|yogh?urt|cheese)\b|\begg-?less\b|\begg-?free\b|\bno eggs?\b/gi;

export function violatesDiet(text, cls) {
  if (cls === 'non-vegetarian') return false;
  const t = String(text || '').replace(PLANT_BASED, ' ');
  if (MEAT_WORDS.test(t)) return true;
  if ((cls === 'vegetarian' || cls === 'vegan') && EGG_WORDS.test(t)) return true;
  if (cls === 'vegan' && DAIRY_WORDS.test(t)) return true;
  return false;
}

/** A dish's label, loosened until its own words fit it ("vegan" filter coffee -> vegetarian). */
export function honestDiet(label, text) {
  let i = DIETS.indexOf(dishDiet(label));
  if (i < 0) return undefined;
  while (i < DIETS.length - 1 && violatesDiet(text, DIETS[i])) i++;
  return DIETS[i];
}

const RULES = {
  vegan: 'VEGAN ONLY: no meat, fish, seafood, eggs, dairy (milk, paneer, ghee, butter, curd, cream, cheese) or honey. Most Indian restaurant curries and sweets use ghee, butter, cream or milk — those are NOT vegan.',
  vegetarian: 'VEGETARIAN: no meat, fish, seafood or eggs (dairy is fine). Vegan dishes are welcome too.',
  eggetarian: 'EGGETARIAN: no meat, fish or seafood. Egg, vegetarian and vegan dishes are all welcome.',
  'non-vegetarian': 'NO RESTRICTION: they eat everything — offer a natural mix of non-veg, egg, vegetarian and vegan options; do not make everything non-veg.',
};

export function dietRule(cls) {
  return RULES[cls] || RULES['non-vegetarian'];
}

export const DISH_DIET_FIELD = `"diet": the dish's own category — "vegan" (no animal products at all), "vegetarian" (dairy but no egg/meat), "eggetarian" (contains egg, no meat/fish) or "non-vegetarian" (contains meat/fish/seafood)`;
