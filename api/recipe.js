// POST /api/recipe  { id, title, imageUrl?, ingredients?, mealType?, flavours?, cookTime?, preferences? }
// -> Recipe JSON (shape of lib/models/recipe.dart), generated on the fly by the LLM.
import { sarvamChat, extractJson, str, strList, num, readBody } from './_sarvam.js';
import { dietClass, dietRule, isAllowed, dishDiet, violatesDiet, DISH_DIET_FIELD } from './_diet.js';

function nutrition(v) {
  if (!v || typeof v !== 'object') return null;
  return {
    calories: Math.round(num(v.calories)),
    proteinG: num(v.proteinG),
    carbsG: num(v.carbsG),
    fatG: num(v.fatG),
    fiberG: num(v.fiberG),
  };
}

function buildPrompt({ title, ingredients, mealType, flavours, cookTime, preferences, diet }) {
  const avoid = strList(preferences?.avoidances).filter((a) => a.toLowerCase() !== 'none');
  return `Write a home-cooking recipe for "${title}" for an Indian home kitchen.
${ingredients.length ? `The user HAS these ingredients: ${ingredients.join(', ')}. Build the recipe around them; you may add common pantry staples (salt, oil, ghee, basic spices, onion, garlic, ginger, green chilli) but avoid other ingredients they didn't mention unless essential — if essential, mark it "(optional)" or "(if available)".` : ''}
${mealType ? `Meal: ${mealType}.` : ''} ${strList(flavours).length ? `They want it: ${strList(flavours).join(', ')}.` : ''} ${cookTime && cookTime !== 'Any time' ? `Total time must fit within ${cookTime}.` : ''}
Diet rule: ${dietRule(diet)} Do NOT use any ingredient this rule forbids, even if the user has it — adapt the dish instead.${avoid.length ? ` Must avoid: ${avoid.join(', ')}.` : ''}

Reply with ONLY this JSON object, no markdown:
{
  "description": "1-2 appetising sentences",
  ${DISH_DIET_FIELD},
  "cuisineType": "e.g. North Indian",
  "prepTimeMinutes": number,
  "cookTimeMinutes": number,
  "ingredients": ["quantity + ingredient", ...],
  "steps": ["clear step", ...],
  "nutrition": {"calories": number, "proteinG": number, "carbsG": number, "fatG": number, "fiberG": number},
  "healthHighlights": ["max 3 short phrases"],
  "tags": ["max 4 short tags"],
  "hasHealthyVersion": boolean,
  "healthyIngredients": [...] or null,
  "healthySteps": [...] or null,
  "healthyNutrition": {same shape} or null
}
Nutrition is per serving and approximate. Only include a healthy version if a meaningfully lighter variant exists; its healthyIngredients and healthySteps must be the COMPLETE ingredient list and steps for that lighter version (not tips).`;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const body = readBody(req);
  const id = str(body.id, 100);
  const title = str(body.title, 120);
  if (!id || !title) return res.status(400).json({ error: 'id and title are required' });

  const params = {
    title,
    ingredients: strList(body.ingredients, 25, 60),
    mealType: str(body.mealType, 20),
    flavours: body.flavours,
    cookTime: str(body.cookTime, 20),
    preferences: body.preferences && typeof body.preferences === 'object' ? body.preferences : {},
  };
  params.diet = dietClass(params.preferences.dietaryType);

  try {
    // Diet compliance is checked from the recipe's own label; regenerate once if it breaks the rule.
    let r;
    for (let attempt = 0; attempt < 2; attempt++) {
      const reply = await sarvamChat({ user: buildPrompt(params), maxTokens: 1800, temperature: 0.4, timeoutMs: 40000 });
      r = extractJson(reply);
      const ingredientText = [title, ...strList(r.ingredients, 40)].join(' | ');
      if (isAllowed(r.diet, params.diet) && !violatesDiet(ingredientText, params.diet)) break;
      console.error(`Recipe diet "${r.diet}" not allowed for ${params.diet}${attempt === 0 ? ', retrying' : ''}`);
      r = null;
    }
    if (!r) throw new Error('Recipe broke the diet rule twice');
    const ingredients = strList(r.ingredients, 40);
    const steps = strList(r.steps, 25, 600);
    const base = nutrition(r.nutrition);
    if (!ingredients.length || !steps.length || !base) throw new Error('Incomplete recipe from LLM');

    const healthyIngredients = strList(r.healthyIngredients, 40);
    const healthySteps = strList(r.healthySteps, 25, 600);
    const healthyNutrition = nutrition(r.healthyNutrition);
    const hasHealthyVersion = Boolean(r.hasHealthyVersion && healthyNutrition && (healthyIngredients.length || healthySteps.length));

    return res.status(200).json({
      id,
      title,
      description: str(r.description, 400) || '',
      imageUrl: str(body.imageUrl, 500) || '',
      mealType: params.mealType || 'meal',
      path: 'cook',
      tags: strList(r.tags, 4, 30),
      healthHighlights: strList(r.healthHighlights, 3, 40),
      nutrition: base,
      healthyNutrition: hasHealthyVersion ? healthyNutrition : null,
      ingredients,
      healthyIngredients: hasHealthyVersion && healthyIngredients.length ? healthyIngredients : null,
      steps,
      healthySteps: hasHealthyVersion && healthySteps.length ? healthySteps : null,
      prepTimeMinutes: Math.round(num(r.prepTimeMinutes, 10)),
      cookTimeMinutes: Math.round(num(r.cookTimeMinutes, 20)),
      cuisineType: str(r.cuisineType, 40) || 'Indian',
      diet: dishDiet(r.diet),
      hasHealthyVersion,
    });
  } catch (err) {
    console.error('Recipe generation failed:', err.message);
    return res.status(502).json({ error: 'Recipe generation failed' });
  }
}
