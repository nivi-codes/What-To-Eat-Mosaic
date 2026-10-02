import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Real-time speech-to-text via Gnani Vachana WebSocket streaming, proxied through
/// /api/stt-stream (browsers can't send the auth header Gnani requires).
/// onTranscript fires with the accumulated text after each speech segment, and once
/// more with isFinal=true after stopListening() flushes the last segment.
class GnaniSpeechService {
  bool _isListening = false;

  void Function(String transcript, bool isFinal)? onTranscript;
  void Function(String error)? onError;
  void Function(String status)? onStatus;

  bool get isListening => _isListening;

  bool get isAvailable {
    try {
      return _gnaniStreamingIsAvailable().toDart;
    } catch (_) {
      return false;
    }
  }

  Future<bool> init() async {
    if (!isAvailable) return false;
    try {
      final result = await _gnaniRequestMicPermission().toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening({String language = 'en'}) async {
    if (_isListening) return;

    _isListening = true;

    globalContext.setProperty(
      '_gnaniOnTranscript'.toJS,
      ((JSString transcript, JSBoolean isFinal) {
        onTranscript?.call(transcript.toDart, isFinal.toDart);
      }).toJS,
    );

    globalContext.setProperty(
      '_gnaniOnError'.toJS,
      ((JSString error) {
        _isListening = false;
        onError?.call(error.toDart);
      }).toJS,
    );

    globalContext.setProperty(
      '_gnaniOnStatus'.toJS,
      ((JSString status) {
        final s = status.toDart;
        onStatus?.call(s);
        if (s == 'disconnected') {
          _isListening = false;
        }
      }).toJS,
    );

    _gnaniStreamingStart('server'.toJS, language.toJS);
  }

  void stopListening() {
    if (!_isListening) return;
    _isListening = false;
    _gnaniStreamingStop();
  }

  void dispose() {
    stopListening();
    onTranscript = null;
    onError = null;
    onStatus = null;
  }
}

@JS('gnaniStreamingStart')
external void _gnaniStreamingStart(JSString apiKey, JSString language);

@JS('gnaniStreamingStop')
external void _gnaniStreamingStop();

@JS('gnaniStreamingIsAvailable')
external JSBoolean _gnaniStreamingIsAvailable();

@JS('gnaniRequestMicPermission')
external JSPromise<JSBoolean> _gnaniRequestMicPermission();
