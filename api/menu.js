// POST /api/menu  { name, cuisine?, vibe?, flavours?, mealType?, preferences? }
// -> { sections: [{ title, items: [{ name, description, price, veg }] }] }
// LLM-generated "what to order here" menu. Not the restaurant's official menu, so
// the client labels it as suggested with approximate prices.
import { sarvamChat, extractJson, str, strList, num, readBody } from './_sarvam.js';
import { dietClass, dietRule, isAllowed, dishDiet, violatesDiet } from './_diet.js';

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const body = readBody(req);
  const name = str(body.name, 120);
  if (!name) return res.status(400).json({ error: 'name is required' });
  const cuisine = str(body.cuisine, 80);
  // The model doesn't reliably honour diet in the prompt, so it's enforced below
  // from each dish's own label.
  const diet = dietClass(body.preferences?.dietaryType);
  const avoid = strList(body.preferences?.avoidances).filter((a) => a.toLowerCase() !== 'none');
  const flavours = strList(body.flavours);

  const prompt = `Suggest what to order at "${name}"${cuisine ? ` (${cuisine})` : ''}, a restaurant in an Indian metro city.
List dishes this kind of restaurant typically serves${str(body.mealType) ? ` for ${body.mealType}` : ''}${flavours.length ? `, favouring ${flavours.join(', ')} options` : ''}.
Diet rule: ${dietRule(diet)}${avoid.length ? ` They avoid: ${avoid.join(', ')}.` : ''} Only list dishes allowed by the rule.

Reply with ONLY this JSON, no markdown:
{"sections": [{"title": "Starters", "items": [{"name": "dish", "description": "under 12 words", "price": number (typical INR), "diet": "vegan" | "vegetarian" | "eggetarian" | "non-vegetarian"}]}]}
Use 3-4 sections (e.g. Starters, Mains, Breads/Rice, Desserts/Drinks) with 3-5 items each.`;

  try {
    const reply = await sarvamChat({ user: prompt, maxTokens: 1500, temperature: 0.5, timeoutMs: 40000 });
    const raw = extractJson(reply);
    const sections = (Array.isArray(raw.sections) ? raw.sections : [])
      .map((s) => ({
        title: str(s?.title, 40) || 'Dishes',
        items: (Array.isArray(s?.items) ? s.items : [])
          .map((it) => ({
            name: str(it?.name, 80),
            description: str(it?.description, 140) || '',
            price: Math.round(num(it?.price)),
            diet: dishDiet(it?.diet),
          }))
          .filter((it) => it.name && isAllowed(it.diet, diet) && !violatesDiet(`${it.name} ${it.description}`, diet))
          .slice(0, 6),
      }))
      .filter((s) => s.items.length)
      .slice(0, 5);
    if (!sections.length) throw new Error('Empty menu from LLM');
    return res.status(200).json({ sections });
  } catch (err) {
    console.error('Menu generation failed:', err.message);
    return res.status(502).json({ error: 'Menu generation failed' });
  }
}
