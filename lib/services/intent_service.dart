import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// LLM-based understanding of free-form user input (/api/intent), cached by text.
/// Live previews use a single quick pass; submits use the more reliable precise pass.
class IntentService {
  static final Map<String, Future<Map<String, dynamic>?>> _cache = {};

  /// Returns detected fields, or null if the LLM is unavailable (callers fall back).
  /// [precise] (used on submit) asks the server for a more reliable multi-pass read.
  static Future<Map<String, dynamic>?> extract(String flowType, String text, {bool precise = false}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value(<String, dynamic>{});
    final key = '$flowType|$precise|${trimmed.toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final future = _request(flowType, trimmed, precise);
    _cache[key] = future;
    future.then((r) {
      if (r == null) _cache.remove(key); // don't cache failures
    });
    if (_cache.length > 100) _cache.remove(_cache.keys.first);
    return future;
  }

  static Future<Map<String, dynamic>?> _request(String flowType, String text, bool precise) async {
    try {
      final res = await http
          .post(
            Uri.parse('/api/intent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'flowType': flowType, 'text': text, 'final': precise}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final detected = data is Map ? data['detected'] : null;
      return detected is Map ? Map<String, dynamic>.from(detected) : null;
    } catch (e) {
      debugPrint('Intent extraction failed: $e');
      return null;
    }
  }
}

/// Live intent extraction while the user speaks or types. Throttled, not
/// debounced: speech updates arrive every ~450 ms, so a debounce would only fire
/// once the user stopped talking. One request at a time, always for the newest
/// text, which also keeps calls well under the provider's rate limit.
class LiveIntent {
  LiveIntent(this.flowType, {this.interval = const Duration(milliseconds: 900)});

  final String flowType;
  final Duration interval;
  Timer? _timer;
  bool _inFlight = false;
  String? _pending;
  int _generation = 0;
  void Function(Map<String, dynamic>? detected)? _onResult;

  void update(String text, void Function(Map<String, dynamic>? detected) onResult) {
    _pending = text;
    _onResult = onResult;
    if (_timer == null && !_inFlight) _timer = Timer(interval, _fire);
  }

  Future<void> _fire() async {
    _timer = null;
    final text = _pending;
    if (text == null) return;
    _pending = null;
    _inFlight = true;
    final generation = _generation;
    final detected = await IntentService.extract(flowType, text);
    _inFlight = false;
    if (generation != _generation) return;
    _onResult?.call(detected);
    // Newer words arrived while this request was out: analyse them next.
    if (_pending != null) _timer = Timer(interval, _fire);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _generation++;
  }
}
