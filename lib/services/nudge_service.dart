import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches contextual nudge questions from Sarvam LLM.
/// Tries /api/nudges (Vercel) first, then calls Sarvam directly
/// using a compile-time key, then falls back to static defaults.
class NudgeService {
  static const _sarvamKey = String.fromEnvironment('SARVAM_API_KEY');
  static Timer? _debounce;

  static Future<List<String>> fetchNudges({
    required String flowType,
    required Map<String, dynamic> detected,
    String transcript = '',
    int count = 5,
    String? dietaryType,
  }) async {
    // 1. Try server endpoint (Vercel)
    try {
      final response = await http.post(
        Uri.parse('/api/nudges'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flowType': flowType,
          'detected': detected,
          'transcript': transcript,
          'count': count,
          'dietaryType': dietaryType,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nudges = data['nudges'] as List<dynamic>?;
        if (nudges != null && nudges.isNotEmpty) {
          return nudges.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    // 2. Call Sarvam directly (local dev with --dart-define)
    if (_sarvamKey.isNotEmpty) {
      try {
        return await _fetchFromSarvamDirect(flowType, detected, transcript, count);
      } catch (e) {
        debugPrint('Direct Sarvam nudge call failed: $e');
      }
    }

    return getDefaultNudges(flowType, detected);
  }

  static Future<List<String>> _fetchFromSarvamDirect(
    String flowType, Map<String, dynamic> detected, String transcript, int count,
  ) async {
    final prompt = _buildPrompt(flowType, detected, transcript, count);
    final response = await http.post(
      Uri.parse('https://api.sarvam.ai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_sarvamKey',
      },
      body: jsonEncode({
        'model': 'sarvam-105b',
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': 300,
        'temperature': 0.7,
        'reasoning_effort': null,
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] ?? '';
      final match = RegExp(r'\[[\s\S]*?\]').firstMatch(text);
      if (match != null) {
        final nudges = (jsonDecode(match.group(0)!) as List)
            .map((e) => e.toString())
            .toList();
        if (nudges.isNotEmpty) return nudges.take(count).toList();
      }
    }
    return getDefaultNudges(flowType, detected);
  }

  static String _buildPrompt(
    String flowType, Map<String, dynamic> detected, String transcript, int count,
  ) {
    final detectedKeys = detected.keys.toList();
    final detectedSummary = detectedKeys.isNotEmpty
        ? detectedKeys.map((k) {
            final v = detected[k];
            return '$k: ${v is List ? v.join(', ') : v}';
          }).join('; ')
        : 'nothing yet';

    if (flowType == 'onboarding') {
      return 'You are a friendly Indian food assistant helping a user set up their food preferences.\n'
          'The user is speaking freely about their food habits. So far they\'ve mentioned: $detectedSummary.\n'
          '${transcript.isNotEmpty ? 'Their current words: "$transcript"\n' : ''}'
          'Generate exactly $count short, friendly follow-up questions (max 6 words each) to learn what\'s STILL MISSING.\n'
          'We need: dietary type (veg/non-veg/vegan/eggetarian), favourite cuisines, preferred flavours, food allergies/avoidances, healthy food preference.\n'
          'ONLY ask about things NOT yet answered. If everything is covered, return encouraging confirmations.\n'
          'Return ONLY a JSON array of strings. No markdown, no explanation.\n'
          'Example: ["Spicy or mild?", "Any food allergies?"]';
    }

    return 'You are a friendly Indian food assistant helping someone decide what to eat RIGHT NOW.\n'
        'They\'ve mentioned: $detectedSummary.\n'
        '${transcript.isNotEmpty ? 'Their words: "$transcript"\n' : ''}'
        'Generate exactly $count short, casual nudge questions (max 6 words each) to help narrow down their choice.\n'
        'We need: meal type (breakfast/lunch/snack/dinner), flavour preference, method (cook/order/dine out).\n'
        'If method is cook: what ingredients they have, how much time.\n'
        'If method is order: cuisine preference.\n'
        'If method is dine: what vibe they want.\n'
        'ONLY ask about things NOT yet answered. Be casual, fun, use Indian food context.\n'
        'Return ONLY a JSON array of strings. No markdown, no explanation.\n'
        'Example: ["Craving something spicy?", "Got time to cook?"]';
  }

  static void fetchNudgesDebounced({
    required String flowType,
    required Map<String, dynamic> detected,
    required String transcript,
    required void Function(List<String>) onResult,
    int count = 5,
    Duration delay = const Duration(milliseconds: 150),
    String? dietaryType,
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () async {
      final nudges = await fetchNudges(
        flowType: flowType,
        detected: detected,
        transcript: transcript,
        count: count,
        dietaryType: dietaryType,
      );
      onResult(nudges);
    });
  }

  static void cancelPending() {
    _debounce?.cancel();
  }

  static List<String> getDefaultNudges(String flowType, Map<String, dynamic> detected) {
    if (flowType == 'onboarding') {
      final nudges = <String>[];
      if (!detected.containsKey('dietary')) nudges.add('Veg or non-veg?');
      if (!detected.containsKey('cuisines')) nudges.add('Favourite cuisines?');
      if (!detected.containsKey('flavours')) nudges.add('Preferred flavours?');
      if (!detected.containsKey('avoidances')) nudges.add('Any allergies?');
      if (!detected.containsKey('healthy')) nudges.add('Healthy or regular?');
      return nudges.isNotEmpty ? nudges : ['Got everything!'];
    }

    final nudges = <String>[];
    if (!detected.containsKey('mealType')) nudges.add('What meal?');
    if (!detected.containsKey('flavours')) nudges.add('What flavour?');
    if (!detected.containsKey('method')) nudges.add('Cook, order, or dine?');
    if (detected['method'] == 'cook') {
      if (!detected.containsKey('ingredients')) nudges.add('What ingredients?');
      if (!detected.containsKey('cookTime')) nudges.add('How much time?');
    }
    if (detected['method'] == 'order' && !detected.containsKey('cuisine')) {
      nudges.add('Any cuisine?');
    }
    if (detected['method'] == 'dine' && !detected.containsKey('vibe')) {
      nudges.add('What vibe?');
    }
    return nudges.isNotEmpty ? nudges : ['Got everything!'];
  }
}
