// POST /api/nudges
// Uses Sarvam LLM to generate contextual nudge questions for onboarding and eat flow.
// Returns an array of short, conversational question strings.
import { sarvamChat, extractJson, strList } from './_sarvam.js';

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
  } = req.body || {};

  try {
    const reply = await sarvamChat({
      user: buildNudgePrompt(flowType, detected, transcript, count),
      maxTokens: 300,
      temperature: 0.7,
      timeoutMs: 10000,
    });
    const nudges = strList(extractJson(reply), count, 60);
    if (nudges.length > 0) return res.status(200).json({ nudges });
  } catch (err) {
    console.error('Sarvam nudge error:', err.message);
  }

  // Fallback to defaults
  return res.status(200).json({ nudges: getDefaultNudges(flowType, detected) });
}

function buildNudgePrompt(flowType, detected, transcript, count) {
  const detectedKeys = Object.keys(detected);
  const detectedSummary = detectedKeys.length > 0
    ? detectedKeys.map(k => `${k}: ${Array.isArray(detected[k]) ? detected[k].join(', ') : detected[k]}`).join('; ')
    : 'nothing yet';

  if (flowType === 'onboarding') {
    return `You are a friendly Indian food assistant helping a user set up their food preferences.
The user is speaking freely about their food habits. So far they've mentioned: ${detectedSummary}.
${transcript ? `Their current words: "${transcript}"` : ''}

Generate exactly ${count} short, friendly follow-up questions (max 6 words each) to learn what's STILL MISSING.
We need to know: dietary type (veg/non-veg/vegan/eggetarian), favourite cuisines, preferred flavours, food allergies/avoidances, and healthy food preference.

ONLY ask about things NOT yet answered. If everything is covered, return encouraging confirmations.
Return ONLY a JSON array of strings. No markdown, no explanation.
Example: ["Spicy or mild?", "Any food allergies?"]`;
  }

  // eat_flow
  return `You are a friendly Indian food assistant helping someone decide what to eat RIGHT NOW.
They've mentioned: ${detectedSummary}.
${transcript ? `Their words: "${transcript}"` : ''}

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
