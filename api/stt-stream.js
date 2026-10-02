// WebSocket proxy: browser <-> Gnani Vachana streaming STT.
// Browsers can't set the x-api-key-id upgrade header Gnani requires, so the
// browser connects here and this function opens the upstream socket with headers.
import { createServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';

const GNANI_WS_URL = 'wss://api.vachana.ai/stt/v3/stream';
const ALLOWED_LANGS = /^[a-z]{2}-IN$/;

const server = createServer((req, res) => {
  res.writeHead(426, { 'Content-Type': 'text/plain' });
  res.end('WebSocket upgrade required');
});

const wss = new WebSocketServer({ server });

function sendJson(socket, obj) {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(obj));
}

wss.on('connection', (client, req) => {
  const apiKey = process.env.GNANI_API_KEY;
  if (!apiKey) {
    sendJson(client, { type: 'error', message: 'GNANI_API_KEY not configured on server' });
    client.close(1011, 'server misconfigured');
    return;
  }

  const params = new URL(req.url, 'http://localhost').searchParams;
  const lang = ALLOWED_LANGS.test(params.get('lang') || '') ? params.get('lang') : 'en-IN';

  const upstream = new WebSocket(GNANI_WS_URL, {
    headers: {
      'x-api-key-id': apiKey,
      'lang_code': lang,
      'x-sample-rate': '16000',
      'x-vad-threshold': '0.5',
      'x-min-silence-ms': '600',
      'x-partials': 'true',
    },
  });

  upstream.on('message', (data, isBinary) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(isBinary ? data : data.toString());
    }
  });

  upstream.on('unexpected-response', (_req, res) => {
    let body = '';
    res.on('data', (chunk) => { body += chunk; });
    res.on('end', () => {
      console.error('Gnani handshake rejected:', res.statusCode, body);
      sendJson(client, { type: 'error', message: `Gnani rejected connection (${res.statusCode})` });
      client.close(1011, 'upstream rejected');
    });
  });

  upstream.on('error', (err) => {
    console.error('Gnani upstream error:', err.message);
    sendJson(client, { type: 'error', message: 'Speech service connection failed' });
    if (client.readyState === WebSocket.OPEN) client.close(1011, 'upstream error');
  });

  upstream.on('close', (code, reason) => {
    if (code !== 1000) console.error('Gnani closed:', code, reason.toString());
    if (client.readyState === WebSocket.OPEN) client.close(1000, 'upstream closed');
  });

  client.on('message', (data, isBinary) => {
    // Audio is only sent after the client receives Gnani's `connected` message,
    // so upstream is always open here unless it is shutting down.
    if (upstream.readyState === WebSocket.OPEN) upstream.send(data, { binary: isBinary });
  });

  client.on('close', () => {
    if (upstream.readyState === WebSocket.OPEN) upstream.close(1000);
    else if (upstream.readyState === WebSocket.CONNECTING) upstream.terminate();
  });

  client.on('error', () => upstream.terminate());
});

export default server;
