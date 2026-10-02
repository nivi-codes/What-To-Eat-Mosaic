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

/// Debounced live intent extraction for one input field; drops stale responses
/// so an older, slower reply never overwrites a newer one.
class LiveIntent {
  // Speech partials arrive every ~450ms while talking, so this only fires on
  // pauses — keeps LLM calls well under the provider's rate limit.
  LiveIntent(this.flowType, {this.delay = const Duration(milliseconds: 700)});

  final String flowType;
  final Duration delay;
  Timer? _timer;
  int _seq = 0;

  void update(String text, void Function(Map<String, dynamic>? detected) onResult) {
    _timer?.cancel();
    final seq = ++_seq;
    _timer = Timer(delay, () async {
      final detected = await IntentService.extract(flowType, text);
      if (seq == _seq) onResult(detected);
    });
  }

  void cancel() {
    _timer?.cancel();
    _seq++;
  }
}
