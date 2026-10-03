// POST /api/nudges
// Uses Sarvam LLM to generate contextual nudge questions for onboarding and eat flow.
// Returns an array of short, conversational question strings.
import { sarvamChat, extractJson, strList } from './_sarvam.js';
import { dietClass, dietRule, violatesDiet } from './_diet.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(200).end();
  }

  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const {
    flowType = 'onboarding',  // 'onboarding' or 'eat_flow'
    detected = {},             // what the user has already answered
    transcript = '',           // current transcript so far
    count = 5,                 // how many nudge questions to generate
    dietaryType = null,        // the profile's diet (eat flow)
  } = req.body || {};
  // Onboarding has no profile yet, so it goes by the diet the user has stated so far.
  const dietSource = dietaryType || detected.dietary;
  const diet = dietSource ? dietClass(dietSource) : null;

  try {
    const reply = await sarvamChat({
      user: buildNudgePrompt(flowType, detected, transcript, count, diet),
      maxTokens: 300,
      temperature: 0.7,
      timeoutMs: 10000,
    });
    // Backstop: the model sometimes still offers e.g. butter chicken to a vegetarian.
    const nudges = strList(extractJson(reply), count, 60).filter((n) => !diet || !violatesDiet(n, diet));
    if (nudges.length > 0) return res.status(200).json({ nudges });
  } catch (err) {
    console.error('Sarvam nudge error:', err.message);
  }

  // Fallback to defaults
  return res.status(200).json({ nudges: getDefaultNudges(flowType, detected) });
}

function buildNudgePrompt(flowType, detected, transcript, count, diet) {
  const detectedKeys = Object.keys(detected);
  const detectedSummary = detectedKeys.length > 0
    ? detectedKeys.map(k => `${k}: ${Array.isArray(detected[k]) ? detected[k].join(', ') : detected[k]}`).join('; ')
    : 'nothing yet';
  const dietLine = diet ? `\nDiet: ${dietRule(diet)} Never mention a dish or ingredient this rule forbids.` : '';

  if (flowType === 'onboarding') {
    return `You are a friendly Indian food assistant helping a user set up their food preferences.
The user is speaking freely about their food habits. So far they've mentioned: ${detectedSummary}.
${transcript ? `Their current words: "${transcript}"` : ''}${dietLine}

Generate exactly ${count} short, friendly follow-up questions (max 6 words each) to learn what's STILL MISSING.
We need to know: dietary type (veg/non-veg/vegan/eggetarian), favourite cuisines, preferred flavours, food allergies/avoidances, and healthy food preference.

ONLY ask about things NOT yet answered. If everything is covered, return encouraging confirmations.
Return ONLY a JSON array of strings. No markdown, no explanation.
Example: ["Spicy or mild?", "Any food allergies?"]`;
  }

  // eat_flow
  return `You are a friendly Indian food assistant helping someone decide what to eat RIGHT NOW.
They've mentioned: ${detectedSummary}.
${transcript ? `Their words: "${transcript}"` : ''}${dietLine}

Generate exactly ${count} short, casual nudge questions (max 6 words each) to help narrow down their choice.
We need: meal type (breakfast/lunch/snack/dinner), flavour preference, method (cook/order/dine out).
If method is cook: what ingredients they have, how much time.
If method is order: cuisine preference.
If method is dine: what vibe they want.

ONLY ask about things NOT yet answered. Be casual, fun, use Indian food context.
Return ONLY a JSON array of strings. No markdown, no explanation.
Example: ["Craving something spicy?", "Got time to cook?"]`;
}

function getDefaultNudges(flowType, detected) {
  if (flowType === 'onboarding') {
    const nudges = [];
    if (!detected.dietary) nudges.push('Veg or non-veg?');
    if (!detected.cuisines) nudges.push('Favourite cuisines?');
    if (!detected.flavours) nudges.push('Preferred flavours?');
    if (!detected.avoidances) nudges.push('Any allergies?');
    if (!detected.healthy) nudges.push('Healthy or regular?');
    return nudges.length > 0 ? nudges : ['All set! 🎉'];
  }

  const nudges = [];
  if (!detected.mealType) nudges.push('What meal?');
  if (!detected.flavours) nudges.push('What flavour?');
  if (!detected.method) nudges.push('Cook, order, or dine?');
  if (detected.method === 'cook') {
    if (!detected.ingredients) nudges.push('What ingredients?');
    if (!detected.cookTime) nudges.push('How much time?');
  }
  if (detected.method === 'order' && !detected.cuisine) nudges.push('Any cuisine?');
  if (detected.method === 'dine' && !detected.vibe) nudges.push('What vibe?');
  return nudges.length > 0 ? nudges : ['Got everything! 🎉'];
}
