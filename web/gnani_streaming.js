// Real-time STT: mic -> AudioWorklet (PCM16 @ 16kHz, 1024-byte frames) -> /api/stt-stream (WebSocket proxy) -> Gnani.
// Gnani emits one `transcript` message per VAD-closed speech segment; segments are accumulated.

(function() {
  'use strict';

  var TARGET_RATE = 16000;
  var FRAME_SAMPLES = 512; // 1024 bytes of PCM16, as Gnani requires
  var FLUSH_SILENCE_MS = 800; // > x-min-silence-ms so VAD closes the last segment
  var FINAL_WAIT_MS = 2500;
  var CONNECT_TIMEOUT_MS = 10000;

  // Downsamples (with box-filter averaging) to 16kHz and posts exact 512-sample Int16 frames.
  var WORKLET_SRC = [
    'class GnaniPcmFramer extends AudioWorkletProcessor {',
    '  constructor() {',
    '    super();',
    '    this.ratio = sampleRate / ' + TARGET_RATE + ';',
    '    this.acc = 0; this.accN = 0; this.pos = 0;',
    '    this.frame = new Int16Array(' + FRAME_SAMPLES + '); this.idx = 0;',
    '  }',
    '  push(v) {',
    '    var s = Math.max(-1, Math.min(1, v));',
    '    this.frame[this.idx++] = s < 0 ? s * 0x8000 : s * 0x7FFF;',
    '    if (this.idx === this.frame.length) {',
    '      this.port.postMessage(this.frame.buffer, [this.frame.buffer]);',
    '      this.frame = new Int16Array(' + FRAME_SAMPLES + '); this.idx = 0;',
    '    }',
    '  }',
    '  process(inputs) {',
    '    var ch = inputs[0] && inputs[0][0];',
    '    if (!ch) return true;',
    '    for (var i = 0; i < ch.length; i++) {',
    '      this.acc += ch[i]; this.accN++; this.pos += 1;',
    '      if (this.pos >= this.ratio) {',
    '        this.pos -= this.ratio;',
    '        this.push(this.acc / this.accN);',
    '        this.acc = 0; this.accN = 0;',
    '      }',
    '    }',
    '    return true;',
    '  }',
    '}',
    'registerProcessor("gnani-pcm-framer", GnaniPcmFramer);'
  ].join('\n');

  var ws = null;
  var audioContext = null;
  var mediaStream = null;
  var sourceNode = null;
  var workletNode = null;
  var sendAudio = false;
  var sessionId = 0;
  var segments = [];        // final text of completed utterances
  var openUtterances = {};  // utterance_id -> latest partial text (speech_start seen, final not yet)
  var finalTimer = null;
  var finalized = true;

  window._gnaniOnTranscript = null;
  window._gnaniOnError = null;
  window._gnaniOnStatus = null;

  function status(s) { if (window._gnaniOnStatus) window._gnaniOnStatus(s); }
  function error(msg) { if (window._gnaniOnError) window._gnaniOnError(msg); }
  function pendingCount() { return Object.keys(openUtterances).length; }
  function fullText() {
    var parts = segments.slice();
    for (var id in openUtterances) if (openUtterances[id]) parts.push(openUtterances[id]);
    return parts.join(' ').trim();
  }
  function emitLive() {
    var text = fullText();
    if (text && window._gnaniOnTranscript) window._gnaniOnTranscript(text, false);
  }

  function teardownAudio() {
    sendAudio = false;
    if (workletNode) { try { workletNode.port.onmessage = null; workletNode.disconnect(); } catch (_) {} workletNode = null; }
    if (sourceNode) { try { sourceNode.disconnect(); } catch (_) {} sourceNode = null; }
    if (mediaStream) { mediaStream.getTracks().forEach(function(t) { t.stop(); }); mediaStream = null; }
    if (audioContext) { try { audioContext.close(); } catch (_) {} audioContext = null; }
  }

  function finalize() {
    if (finalized) return;
    finalized = true;
    if (finalTimer) { clearTimeout(finalTimer); finalTimer = null; }
    teardownAudio();
    if (ws) {
      var sock = ws;
      ws = null;
      sock.onmessage = sock.onerror = sock.onclose = null;
      try { sock.close(1000); } catch (_) {}
    }
    var text = fullText();
    if (text && window._gnaniOnTranscript) window._gnaniOnTranscript(text, true);
    status('disconnected');
  }

  async function createAudioGraph(stream) {
    // Prefer a 16kHz context so the browser does high-quality resampling; some browsers
    // refuse to connect a mic stream to a context at a different rate, so fall back.
    var ctx;
    var source;
    try {
      ctx = new AudioContext({ sampleRate: TARGET_RATE });
      source = ctx.createMediaStreamSource(stream);
    } catch (_) {
      if (ctx) { try { ctx.close(); } catch (_) {} }
      ctx = new AudioContext();
      source = ctx.createMediaStreamSource(stream);
    }
    if (ctx.state === 'suspended') await ctx.resume();

    var url = URL.createObjectURL(new Blob([WORKLET_SRC], { type: 'application/javascript' }));
    try {
      await ctx.audioWorklet.addModule(url);
    } finally {
      URL.revokeObjectURL(url);
    }
    var node = new AudioWorkletNode(ctx, 'gnani-pcm-framer', {
      numberOfInputs: 1, numberOfOutputs: 1, channelCount: 1,
    });
    source.connect(node);
    // Keep the graph pulling audio; the worklet outputs silence.
    node.connect(ctx.destination);
    return { ctx: ctx, source: source, node: node };
  }

  window.gnaniStreamingStart = async function(_unused, language) {
    if (finalTimer) { clearTimeout(finalTimer); finalTimer = null; }
    if (ws) { ws.onmessage = ws.onerror = ws.onclose = null; try { ws.close(); } catch (_) {} ws = null; }
    teardownAudio();

    var mySession = ++sessionId;
    var lang = language || 'en-IN';
    if (lang.indexOf('-') === -1) lang = lang + '-IN';
    segments = [];
    openUtterances = {};
    finalized = false;

    // UI shows "getting ready" until both the mic and Gnani are live; only then
    // does it tell the user to speak (status 'listening').
    status('connecting');
    var upstreamReady = false;
    var micReady = false;
    function maybeReady() {
      if (!upstreamReady || !micReady || sendAudio || finalized || mySession !== sessionId) return;
      clearTimeout(connectTimer);
      sendAudio = true;
      status('listening');
    }
    var connectTimer = setTimeout(function() {
      if (mySession !== sessionId || finalized || sendAudio) return;
      error('Speech service took too long to connect. Please try again.');
      finalize();
    }, CONNECT_TIMEOUT_MS);

    try {
      // Open the socket first so the Gnani handshake overlaps with mic setup.
      var proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
      ws = new WebSocket(proto + '//' + location.host + '/api/stt-stream?lang=' + encodeURIComponent(lang));
      ws.binaryType = 'arraybuffer';

      ws.onmessage = function(event) {
        if (typeof event.data !== 'string') return;
        var msg;
        try { msg = JSON.parse(event.data); } catch (_) { return; }

        if (msg.type === 'connected') {
          upstreamReady = true;
          maybeReady();
        } else if (msg.type === 'speech_start') {
          openUtterances[msg.utterance_id || '_'] = '';
        } else if (msg.type === 'partial_transcript') {
          openUtterances[msg.utterance_id || '_'] = (msg.text || '').trim();
          emitLive();
        } else if (msg.type === 'final_transcript' || msg.type === 'transcript') {
          if (msg.utterance_id) delete openUtterances[msg.utterance_id];
          else openUtterances = {};
          var text = (msg.text || '').trim();
          if (text) segments.push(text);
          emitLive();
        } else if (msg.type === 'error') {
          console.error('Gnani error:', msg.message);
          error(msg.message || 'Speech service error');
          finalize();
        }
      };

      ws.onerror = function() {
        console.error('STT WebSocket error');
      };

      ws.onclose = function(e) {
        if (finalized) return;
        if (!sendAudio && !segments.length) {
          error('Could not connect to speech service' + (e.code ? ' (' + e.code + ')' : ''));
        }
        finalize();
      };

      var stream = await navigator.mediaDevices.getUserMedia({
        audio: { channelCount: 1, echoCancellation: true, noiseSuppression: true, autoGainControl: true },
      });
      if (mySession !== sessionId || finalized) {
        stream.getTracks().forEach(function(t) { t.stop(); });
        return;
      }
      mediaStream = stream;

      var graph = await createAudioGraph(mediaStream);
      if (mySession !== sessionId || finalized) { try { graph.ctx.close(); } catch (_) {} return; }
      audioContext = graph.ctx; sourceNode = graph.source; workletNode = graph.node;
      workletNode.port.onmessage = function(e) {
        if (sendAudio && ws && ws.readyState === WebSocket.OPEN) ws.send(e.data);
      };
      micReady = true;
      maybeReady();
    } catch (err) {
      clearTimeout(connectTimer);
      console.error('Mic/stream start failed:', err);
      var name = err && err.name;
      error(name === 'NotAllowedError' ? 'Microphone permission denied'
        : name === 'NotFoundError' ? 'No microphone found'
        : (err && err.message) || 'Failed to start microphone');
      finalize();
    }
  };

  window.gnaniStreamingStop = function() {
    if (finalized) return;

    // Stop capturing the mic, then send trailing silence so VAD closes the
    // in-progress segment, and wait briefly for its transcript.
    var canFlush = sendAudio && ws && ws.readyState === WebSocket.OPEN;
    teardownAudio();
    if (!canFlush) { finalize(); return; }

    var silence = new ArrayBuffer(FRAME_SAMPLES * 2);
    var framesLeft = Math.ceil(FLUSH_SILENCE_MS / 32);
    var sock = ws;
    var stopSession = sessionId;
    var flushDone = false;
    var interval = setInterval(function() {
      if (finalized || sock.readyState !== WebSocket.OPEN) { clearInterval(interval); return; }
      if (framesLeft-- > 0) { sock.send(silence); return; }
      clearInterval(interval);
      // Grace period for VAD to emit `processing` for the final segment.
      setTimeout(function() {
        if (stopSession !== sessionId) return;
        flushDone = true;
        if (pendingCount() === 0) finalize();
      }, 300);
    }, 32);

    finalTimer = setTimeout(finalize, FLUSH_SILENCE_MS + FINAL_WAIT_MS);
    var prevOnMessage = sock.onmessage;
    sock.onmessage = function(event) {
      prevOnMessage.call(sock, event);
      if (flushDone && pendingCount() === 0) finalize();
    };
  };

  window.gnaniStreamingIsAvailable = function() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia &&
      window.AudioContext && window.AudioWorkletNode && window.WebSocket);
  };

  window.gnaniRequestMicPermission = async function() {
    try {
      var stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach(function(t) { t.stop(); });
      return true;
    } catch (err) {
      console.error('Mic permission request failed:', err && err.name, err && err.message);
      return false;
    }
  };

})();
