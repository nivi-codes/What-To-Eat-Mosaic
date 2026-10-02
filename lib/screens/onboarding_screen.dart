import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/preferences_provider.dart';
import '../services/gnani_speech_service.dart';
import '../services/intent_service.dart';
import '../services/nudge_service.dart';
import '../widgets/understanding_indicator.dart';
import '../widgets/voice_mic_button.dart';

/// Unified onboarding — voice-first with keyboard toggle.
/// Uses Gnani WebSocket streaming for real-time transcription
/// and Sarvam LLM for dynamic nudge questions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _voiceMode = true;
  bool _listening = false; // session active (getting ready or streaming)
  bool _micReady = false; // stream connected — safe for the user to talk
  bool _understanding = false; // waiting on LLM to interpret the free input
  final _liveIntent = LiveIntent('onboarding');
  String _transcript = '';

  bool _freeInputDone = false;
  int _guidedStep = 0;

  String? _dietaryType;
  final Set<String> _cuisines = {};
  final Set<String> _flavours = {};
  final Set<String> _avoidances = {};
  String? _healthyPreference;

  Map<String, dynamic> _detected = {};
  List<String> _remainingQuestions = [];

  final _textController = TextEditingController();
  Timer? _textDebounce;

  // Gnani streaming service
  final GnaniSpeechService _gnaniService = GnaniSpeechService();
  bool _gnaniAvailable = false;

  static const _dietaryOptions = ['Vegetarian', 'Vegan', 'Eggetarian', 'Non-vegetarian'];
  static const _cuisineOptions = [
    'North Indian', 'South Indian', 'Street Food', 'Chinese',
    'Italian', 'Continental', 'Mughlai', 'Gujarati',
  ];
  static const _flavourOptions = [
    'Spicy', 'Light', 'Comforting', 'Sweet',
    'Tangy', 'Rich', 'Fresh', 'Smoky',
  ];
  static const _avoidanceOptions = ['Dairy', 'Gluten', 'Nuts', 'None'];
  static const _healthyOptions = [
    'Healthy first',
    'Regular first',
    'Show both',
    'No preference',
  ];

  @override
  void initState() {
    super.initState();
    _remainingQuestions = NudgeService.getDefaultNudges('onboarding', {});
    _initGnani();
    _textController.addListener(_onTextChanged);
    _fetchInitialNudges();
  }

  Future<void> _initGnani() async {
    _gnaniAvailable = _gnaniService.isAvailable;

    _gnaniService.onTranscript = (transcript, isFinal) {
      if (!mounted) return;
      setState(() => _transcript = transcript);
      _analyzeLive(transcript);

      if (isFinal && transcript.isNotEmpty) {
        setState(() => _listening = false);
        _processInput(transcript);
      }
    };

    _gnaniService.onError = (error) {
      if (!mounted) return;
      debugPrint('Gnani error: $error');
      setState(() {
        _listening = false;
        _gnaniAvailable = false;
        _voiceMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice error: $error. Switched to text input.')),
      );
    };

    _gnaniService.onStatus = (status) {
      debugPrint('Gnani status: $status');
      if (!mounted) return;
      if (status == 'listening' && _listening) {
        setState(() => _micReady = true);
      } else if (status == 'disconnected') {
        setState(() {
          _listening = false;
          _micReady = false;
        });
      }
    };

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _liveIntent.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textDebounce?.cancel();
    _gnaniService.dispose();
    NudgeService.cancelPending();
    super.dispose();
  }

  // ── Sarvam LLM nudge fetching ────────────────────────────────────────────

  void _fetchInitialNudges() {
    NudgeService.fetchNudgesDebounced(
      flowType: 'onboarding',
      detected: {},
      transcript: '',
      onResult: (nudges) {
        if (mounted) setState(() => _remainingQuestions = nudges);
      },
      delay: const Duration(milliseconds: 200),
    );
  }

  void _fetchSmartNudges(String transcript, Map<String, dynamic> detected) {
    NudgeService.fetchNudgesDebounced(
      flowType: 'onboarding',
      detected: detected,
      transcript: transcript,
      onResult: (nudges) {
        if (mounted) setState(() => _remainingQuestions = nudges);
      },
    );
  }

  // ── Real-time transcript analysis ─────────────────────────────────────────

  static Map<String, dynamic> _analyzeOnboardingTranscript(String text) {
    final lower = text.toLowerCase();
    final result = <String, dynamic>{};

    if (lower.contains('non-veg') || lower.contains('non veg') || lower.contains('nonveg')) {
      result['dietary'] = 'Non-vegetarian';
    } else if (lower.contains('vegan')) {
      result['dietary'] = 'Vegan';
    } else if (lower.contains('egg')) {
      result['dietary'] = 'Eggetarian';
    } else if (lower.contains('vegetarian') || lower.contains('veg')) {
      result['dietary'] = 'Vegetarian';
    }

    final cuisines = <String>[];
    for (final c in _cuisineOptions) {
      if (lower.contains(c.toLowerCase())) cuisines.add(c);
    }
    if (cuisines.isNotEmpty) result['cuisines'] = cuisines;

    final flavours = <String>[];
    final flavourMap = {
      'spicy': 'Spicy', 'light': 'Light', 'comfort': 'Comforting',
      'sweet': 'Sweet', 'tangy': 'Tangy', 'rich': 'Rich',
      'fresh': 'Fresh', 'smoky': 'Smoky',
    };
    for (final e in flavourMap.entries) {
      if (lower.contains(e.key)) flavours.add(e.value);
    }
    if (flavours.isNotEmpty) result['flavours'] = flavours;

    final avoidances = <String>[];
    if (lower.contains('dairy')) avoidances.add('Dairy');
    if (lower.contains('gluten')) avoidances.add('Gluten');
    if (lower.contains('nuts') || lower.contains('nut allerg')) avoidances.add('Nuts');
    if (lower.contains('no allerg') || lower.contains('nothing') || lower.contains('no restriction')) {
      avoidances.clear();
      avoidances.add('None');
    }
    if (avoidances.isNotEmpty) result['avoidances'] = avoidances;

    if (lower.contains('healthy first') || lower.contains('healthy option') || lower.contains('prefer healthy')) {
      result['healthy'] = 'Healthy first';
    } else if (lower.contains('regular') && lower.contains('first')) {
      result['healthy'] = 'Regular first';
    } else if (lower.contains('healthy')) {
      result['healthy'] = 'Healthy first';
    }

    return result;
  }

  // ── Voice input (Gnani WebSocket) ────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_gnaniAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available. Please use text input.')),
      );
      setState(() => _voiceMode = false);
      return;
    }

    // Show "getting ready" right away — also covers the browser permission prompt.
    setState(() {
      _listening = true;
      _micReady = false;
      _transcript = '';
      _detected = {};
      _remainingQuestions = NudgeService.getDefaultNudges('onboarding', {});
    });

    final ok = await _gnaniService.init();
    if (!mounted || !_listening) return;
    if (!ok) {
      setState(() {
        _listening = false;
        _gnaniAvailable = false;
        _voiceMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied. Please allow mic access and try again.')),
      );
      return;
    }

    _gnaniService.startListening(language: 'en');
  }

  void _stopListening() {
    // The final transcript (including the last segment) arrives via onTranscript.
    _gnaniService.stopListening();
    setState(() {
      _listening = false;
      _micReady = false;
    });
  }

  // ── Text input with live analysis ─────────────────────────────────────────

  void _onTextChanged() {
    _textDebounce?.cancel();
    final len = _textController.text.trim().length;
    final delay = len < 5 ? 400 : len < 15 ? 200 : 80;
    _textDebounce = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _analyzeLive(text);
      } else {
        _liveIntent.cancel();
        setState(() {
          _detected = {};
        });
        _fetchInitialNudges();
      }
    });
  }

  // LLM understanding while the user is still speaking/typing; keyword fallback offline.
  void _analyzeLive(String text) {
    _liveIntent.update(text, (detected) {
      if (!mounted || _understanding || _freeInputDone) return;
      final d = detected ?? _analyzeOnboardingTranscript(text);
      setState(() => _detected = d);
      _fetchSmartNudges(text, d);
    });
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _processInput(text);
  }

  // ── Parse free input and figure out what's missing ────────────────────────

  Future<void> _processInput(String text) async {
    if (_understanding) return;
    setState(() => _understanding = true);
    final detected = await IntentService.extract('onboarding', text, precise: true) ?? _analyzeOnboardingTranscript(text);
    if (!mounted) return;
    _understanding = false;
    _detected = detected;

    if (detected.containsKey('dietary')) _dietaryType = detected['dietary'];
    if (detected.containsKey('cuisines')) {
      _cuisines.addAll(List<String>.from(detected['cuisines']));
    }
    if (detected.containsKey('flavours')) {
      _flavours.addAll(List<String>.from(detected['flavours']));
    }
    if (detected.containsKey('avoidances')) {
      _avoidances.addAll(List<String>.from(detected['avoidances']));
    }
    if (detected.containsKey('healthy')) _healthyPreference = detected['healthy'];

    setState(() {
      _freeInputDone = true;
      _guidedStep = _findFirstMissingStep();
    });
  }

  int _findFirstMissingStep() {
    if (_dietaryType == null) return 0;
    if (_cuisines.isEmpty) return 1;
    if (_flavours.isEmpty) return 2;
    if (_avoidances.isEmpty) return 3;
    if (_healthyPreference == null) return 4;
    return 5;
  }

  // ── Guided step navigation ────────────────────────────────────────────────

  void _selectGuidedOption(String value) {
    switch (_guidedStep) {
      case 0:
        _dietaryType = value;
      case 1:
        if (_cuisines.contains(value)) {
          _cuisines.remove(value);
        } else {
          _cuisines.add(value);
        }
        return setState(() {});
      case 2:
        if (_flavours.contains(value)) {
          _flavours.remove(value);
        } else {
          _flavours.add(value);
        }
        return setState(() {});
      case 3:
        if (value == 'None') {
          _avoidances.clear();
          _avoidances.add('None');
          setState(() {
            _guidedStep = _findNextMissingStep(_guidedStep + 1);
          });
          return;
        } else {
          _avoidances.remove('None');
          if (_avoidances.contains(value)) {
            _avoidances.remove(value);
          } else {
            _avoidances.add(value);
          }
        }
        return setState(() {});
      case 4:
        _healthyPreference = value;
    }

    setState(() {
      _guidedStep = _findNextMissingStep(_guidedStep + 1);
    });
  }

  int _findNextMissingStep(int from) {
    for (int i = from; i <= 4; i++) {
      switch (i) {
        case 0: if (_dietaryType == null) return 0;
        case 1: if (_cuisines.isEmpty) return 1;
        case 2: if (_flavours.isEmpty) return 2;
        case 3: if (_avoidances.isEmpty) return 3;
        case 4: if (_healthyPreference == null) return 4;
      }
    }
    return 5;
  }

  void _advanceGuidedStep() {
    setState(() {
      _guidedStep = _findNextMissingStep(_guidedStep + 1);
    });
  }

  void _goBackGuided() {
    if (_guidedStep > 0) {
      setState(() => _guidedStep--);
    } else {
      setState(() => _freeInputDone = false);
    }
  }

  void _finishOnboarding() {
    final prefs = context.read<PreferencesProvider>();
    if (_dietaryType != null) {
      prefs.setDietaryType(_dietaryType!.toLowerCase().replaceAll(' ', '-'));
    }
    if (_cuisines.isNotEmpty) prefs.setCuisines(_cuisines.toList());
    if (_flavours.isNotEmpty) {
      prefs.setFlavours(_flavours.map((f) => f.toLowerCase()).toList());
    }
    if (_avoidances.isNotEmpty && !_avoidances.contains('None')) {
      prefs.setAvoidances(_avoidances.map((a) => a.toLowerCase()).toList());
    }
    final healthMap = {
      'Healthy first': 'healthy_first',
      'Regular first': 'regular_first',
      'Show both': 'both',
      'No preference': 'both',
    };
    prefs.setHealthyPreference(healthMap[_healthyPreference] ?? 'both');
    prefs.setInputMode(_voiceMode ? 'voice' : 'tap');
    prefs.completeOnboarding();
    context.go('/onboarding/done');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_freeInputDone) {
      return _buildFreeInputScreen(context);
    }
    if (_guidedStep >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishOnboarding();
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return _buildGuidedStep(context);
  }

  // ── Free Input Screen ─────────────────────────────────────────────────────

  Widget _buildFreeInputScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('About you'),
        actions: [
          IconButton(
            icon: Icon(_voiceMode ? Icons.keyboard : Icons.mic),
            onPressed: () => setState(() {
              _voiceMode = !_voiceMode;
              if (_listening) {
                _gnaniService.stopListening();
                _listening = false;
                _micReady = false;
              }
            }),
            tooltip: _voiceMode ? 'Switch to keyboard' : 'Switch to voice',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell me about your\neveryday food preferences',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _voiceMode
                    ? 'Speak freely — I\'ll pick up what matters'
                    : 'Type what you usually eat — I\'ll analyse as you go',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Dynamic nudge chips (Sarvam LLM powered)
              _OnboardingNudgeBar(
                remaining: _remainingQuestions,
                detected: _detected,
                listening: _listening,
                isVoice: _voiceMode,
              ),

              const Spacer(),

              if (_voiceMode) ...[
                if (_transcript.isNotEmpty)
                  _TranscriptBox(transcript: _transcript, detected: _detected, labelFor: _labelFor),

                if (_understanding)
                  const UnderstandingIndicator()
                else
                  Center(
                    child: VoiceMicButton(
                      phase: !_listening
                          ? MicPhase.idle
                          : _micReady
                              ? MicPhase.listening
                              : MicPhase.connecting,
                      onTap: _listening ? _stopListening : _startListening,
                    ),
                  ),
              ] else ...[
                // Text mode with live detected tags
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'E.g., I\'m vegetarian, love South Indian and street food, usually like spicy and tangy flavours...',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (_detected.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _detected.entries.map((e) {
                      final val = e.value is List
                          ? (e.value as List).join(', ')
                          : e.value.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_labelFor(e.key)}: $val',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                if (_understanding)
                  const UnderstandingIndicator(label: 'Understanding…')
                else
                  ElevatedButton(
                    onPressed: _submitText,
                    child: const Text('Continue'),
                  ),
              ],

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _freeInputDone = true;
                    _guidedStep = 0;
                  });
                },
                child: const Text('Skip — I\'ll pick from options'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'dietary': return 'Diet';
      case 'cuisines': return 'Cuisines';
      case 'flavours': return 'Flavours';
      case 'avoidances': return 'Avoids';
      case 'healthy': return 'Priority';
      default: return key;
    }
  }

  // ── Guided Step Screen ────────────────────────────────────────────────────

  Widget _buildGuidedStep(BuildContext context) {
    final stepConfigs = [
      _GuidedStepConfig(
        question: 'How do you usually eat?',
        subtitle: 'Your day-to-day dietary preference',
        options: _dietaryOptions,
        selected: _dietaryType != null ? {_dietaryType!} : {},
        multiSelect: false,
      ),
      _GuidedStepConfig(
        question: 'Cuisines you love?',
        subtitle: 'Pick as many as you like',
        options: _cuisineOptions,
        selected: _cuisines,
        multiSelect: true,
      ),
      _GuidedStepConfig(
        question: 'Flavours you usually go for?',
        subtitle: 'Pick as many as you like',
        options: _flavourOptions,
        selected: _flavours,
        multiSelect: true,
      ),
      _GuidedStepConfig(
        question: 'Anything you avoid?',
        subtitle: 'Pick any that apply, or choose None',
        options: _avoidanceOptions,
        selected: _avoidances,
        multiSelect: true,
      ),
      _GuidedStepConfig(
        question: 'How do you feel about healthy food?',
        subtitle: 'We\'ll prioritise accordingly',
        options: _healthyOptions,
        selected: _healthyPreference != null ? {_healthyPreference!} : {},
        multiSelect: false,
      ),
    ];

    final config = stepConfigs[_guidedStep];
    final progress = (_guidedStep + 1) / stepConfigs.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackGuided,
        ),
        title: Text('${_guidedStep + 1} of ${stepConfigs.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.cardBorder,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                config.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                config.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Expanded(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: config.options.map((opt) {
                    final isSelected = config.selected.contains(opt);
                    return _OptionTile(
                      label: opt,
                      selected: isSelected,
                      onTap: () => _selectGuidedOption(opt),
                    );
                  }).toList(),
                ),
              ),

              if (config.multiSelect) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: config.selected.isNotEmpty ? _advanceGuidedStep : null,
                  child: const Text('Next'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _advanceGuidedStep,
                child: const Text('Skip'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transcript Box with detected tags ──────────────────────────────────────

class _TranscriptBox extends StatelessWidget {
  const _TranscriptBox({
    required this.transcript,
    required this.detected,
    required this.labelFor,
  });

  final String transcript;
  final Map<String, dynamic> detected;
  final String Function(String) labelFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(transcript, style: Theme.of(context).textTheme.bodyLarge),
          if (detected.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detected.entries.map((e) {
                final val = e.value is List
                    ? (e.value as List).join(', ')
                    : e.value.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${labelFor(e.key)}: $val',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Live Nudge Bar for Onboarding (Sarvam LLM powered) ──────────────────────

class _OnboardingNudgeBar extends StatelessWidget {
  const _OnboardingNudgeBar({
    required this.remaining,
    required this.detected,
    required this.listening,
    required this.isVoice,
  });

  final List<String> remaining;
  final Map<String, dynamic> detected;
  final bool listening;
  final bool isVoice;

  @override
  Widget build(BuildContext context) {
    if (detected.isEmpty && !listening) {
      if (isVoice) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _HintBubble('"I\'m vegetarian, love South Indian"'),
            _HintBubble('"Usually spicy, avoid dairy"'),
            _HintBubble('"Show healthy options first"'),
          ],
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: remaining.map((q) => _NudgeChip(q, active: false)).toList(),
      );
    }

    if (remaining.isEmpty || (remaining.length == 1 && remaining.first.contains('Got everything'))) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Got everything!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final active = listening || !isVoice;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: remaining.map((q) => _NudgeChip(q, active: active)).toList(),
      ),
    );
  }
}

class _NudgeChip extends StatelessWidget {
  const _NudgeChip(this.text, {required this.active});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.surface : AppColors.tagBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 14, color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: active ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ──────────────────────────────────────────────────────

class _GuidedStepConfig {
  final String question;
  final String subtitle;
  final List<String> options;
  final Set<String> selected;
  final bool multiSelect;

  _GuidedStepConfig({
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selected,
    this.multiSelect = false,
  });
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}
