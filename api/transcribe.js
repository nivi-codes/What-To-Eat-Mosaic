// POST /api/transcribe
// Body: { audio: "<base64 encoded audio>", mimeType: "audio/webm", language: "en-IN" }
// Returns: { text: "transcribed text" }
// Uses Gnani Vachana REST STT API (POST https://api.vachana.ai/stt/v3)

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(200).end();
  }

  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { audio, mimeType = 'audio/webm', language = 'en-IN' } = req.body || {};
  if (!audio) return res.status(400).json({ error: 'audio field is required' });

  const apiKey = process.env.GNANI_API_KEY;
  if (!apiKey) {
    return res.status(200).json({ text: '', error: 'GNANI_API_KEY not configured' });
  }

  try {
    const audioBuffer = Buffer.from(audio, 'base64');

    const ext = mimeType.includes('ogg') ? 'ogg'
      : mimeType.includes('wav') ? 'wav'
      : mimeType.includes('mp3') ? 'mp3'
      : mimeType.includes('flac') ? 'flac'
      : mimeType.includes('aac') ? 'aac'
      : mimeType.includes('m4a') ? 'm4a'
      : 'ogg';
    const cleanMime = `audio/${ext}`;
    const formData = new FormData();
    const blob = new Blob([audioBuffer], { type: cleanMime });
    formData.append('audio_file', blob, `recording.${ext}`);
    formData.append('language_code', language);

    const response = await fetch('https://api.vachana.ai/stt/v3', {
      method: 'POST',
      headers: {
        'X-API-Key-ID': apiKey,
      },
      body: formData,
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Gnani API error:', response.status, errText);
      return res.status(200).json({ text: '', error: `Gnani API error: ${response.status}` });
    }

    const data = await response.json();
    const text = data.transcript || data.text || data.result || '';
    return res.status(200).json({ text, success: true });
  } catch (err) {
    console.error('Transcription error:', err.message);
    return res.status(200).json({ text: '', error: err.message });
  }
}
