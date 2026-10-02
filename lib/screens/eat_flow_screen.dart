import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/eat_flow_provider.dart';
import '../services/gnani_speech_service.dart';
import '../services/nudge_service.dart';
import '../services/intent_service.dart';
import '../widgets/understanding_indicator.dart';
import '../widgets/voice_mic_button.dart';
import '../widgets/doodles.dart';

class EatFlowScreen extends StatelessWidget {
  const EatFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EatFlowProvider>(
      builder: (context, flow, _) {
        if (flow.currentStep == EatFlowStep.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/eat/suggestions');
          });
        }
        if (flow.currentStep == EatFlowStep.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(flow.errorMessage ?? 'Something went wrong')),
              );
              flow.reset();
              context.go('/eat');
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                flow.reset();
                context.go('/eat');
              },
            ),
            title: const Text('What do you want?'),
            actions: [
              if (flow.currentStep != EatFlowStep.freeInput &&
                  flow.currentStep != EatFlowStep.loading)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => flow.goBack(),
                  tooltip: 'Back',
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(
                value: _stepProgress(flow),
                backgroundColor: AppColors.divider,
                color: AppColors.chilli,
                minHeight: 4,
              ),
            ),
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _buildStep(context, flow),
            ),
          ),
        );
      },
    );
  }

  double _stepProgress(EatFlowProvider flow) {
    final total = flow.totalSteps + 1;
    final current = flow.currentStepIndex;
    return (current / total).clamp(0.0, 1.0);
  }

  Widget _buildStep(BuildContext context, EatFlowProvider flow) {
    switch (flow.currentStep) {
      case EatFlowStep.freeInput:
        return _FreeInputStep(key: const ValueKey('freeInput'));
      case EatFlowStep.selectMealType:
        return const _MealTypeStep(key: ValueKey('mealType'));
      case EatFlowStep.selectFlavour:
        return const _FlavourStep(key: ValueKey('flavour'));
      case EatFlowStep.selectMethod:
        return const _MethodStep(key: ValueKey('method'));
      case EatFlowStep.pathCookIngredients:
        return _IngredientsStep(key: const ValueKey('ingredients'));
      case EatFlowStep.pathCookTime:
        return const _CookTimeStep(key: ValueKey('cookTime'));
      case EatFlowStep.pathOrderCuisine:
        return const _CuisineStep(key: ValueKey('cuisine'));
      case EatFlowStep.pathDineVibe:
        return const _VibeStep(key: ValueKey('vibe'));
      case EatFlowStep.loading:
        return const _LoadingStep(key: ValueKey('loading'));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Free Input Step (Gnani voice + Sarvam LLM nudges) ─────────────────────────

class _FreeInputStep extends StatefulWidget {
  const _FreeInputStep({super.key});

  @override
  State<_FreeInputStep> createState() => _FreeInputStepState();
}

class _FreeInputStepState extends State<_FreeInputStep> {
  bool _listening = false; // session active (getting ready or streaming)
  bool _micReady = false; // stream connected — safe for the user to talk
  String _transcript = '';
  final _textController = TextEditingController();
  Timer? _textDebounce;
  final _liveIntent = LiveIntent('eat_flow');

  Map<String, dynamic> _detected = {};
  List<String> _remainingQuestions = [];

  final GnaniSpeechService _gnaniService = GnaniSpeechService();
  bool _gnaniAvailable = false;

  @override
  void initState() {
    super.initState();
    _remainingQuestions = NudgeService.getDefaultNudges('eat_flow', {});
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
        context.read<EatFlowProvider>().submitFreeInput(transcript);
      }
    };

    _gnaniService.onError = (error) {
      if (!mounted) return;
      debugPrint('Gnani error: $error');
      setState(() {
        _listening = false;
        _gnaniAvailable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice error: $error')),
      );
      context.read<EatFlowProvider>().toggleInputMode();
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
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textDebounce?.cancel();
    _liveIntent.cancel();
    _gnaniService.dispose();
    NudgeService.cancelPending();
    super.dispose();
  }

  void _fetchInitialNudges() {
    NudgeService.fetchNudgesDebounced(
      flowType: 'eat_flow',
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
      flowType: 'eat_flow',
      detected: detected,
      transcript: transcript,
      onResult: (nudges) {
        if (mounted) setState(() => _remainingQuestions = nudges);
      },
    );
  }

  Future<void> _startListening() async {
    if (!_gnaniAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available. Please use text input.')),
      );
      context.read<EatFlowProvider>().toggleInputMode();
      return;
    }

    // Show "getting ready" right away — also covers the browser permission prompt.
    setState(() {
      _listening = true;
      _micReady = false;
      _transcript = '';
      _detected = {};
      _remainingQuestions = NudgeService.getDefaultNudges('eat_flow', {});
    });

    final ok = await _gnaniService.init();
    if (!mounted || !_listening) return;
    if (!ok) {
      setState(() {
        _listening = false;
        _gnaniAvailable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied. Please allow mic access and try again.')),
      );
      context.read<EatFlowProvider>().toggleInputMode();
      return;
    }

    _gnaniService.startListening(language: 'en');
  }

  void _stopListening() {
    _gnaniService.stopListening();
    setState(() {
      _listening = false;
      _micReady = false;
    });
  }

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
        setState(() => _detected = {});
        _fetchInitialNudges();
      }
    });
  }

  // LLM understanding while the user is still speaking/typing; keyword fallback offline.
  void _analyzeLive(String text) {
    _liveIntent.update(text, (detected) {
      if (!mounted) return;
      final d = detected ?? EatFlowProvider.analyzeTranscript(text);
      setState(() => _detected = d);
      _fetchSmartNudges(text, d);
    });
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<EatFlowProvider>().submitFreeInput(text);
  }

  void _skipToQuestions() {
    context.read<EatFlowProvider>().submitFreeInput('');
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EatFlowProvider>();
    final isVoice = flow.isVoiceMode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What are you in the mood for?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isVoice
                ? 'Speak freely — I\'ll figure out the rest'
                : 'Type what you\'re feeling — I\'ll handle the details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          _LiveNudgeBar(
            remaining: _remainingQuestions,
            detected: _detected,
            listening: _listening,
            isVoice: isVoice,
          ),

          const Spacer(),

          if (isVoice) ...[
            if (_transcript.isNotEmpty)
              Container(
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
                    Text(_transcript, style: Theme.of(context).textTheme.bodyLarge),
                    if (_detected.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _detected.entries.map((e) {
                          final val = e.value is List ? (e.value as List).join(', ') : e.value.toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  ],
                ),
              ),

            if (flow.isUnderstanding)
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., "Spicy dinner, cook at home with paneer"',
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
                  final val = e.value is List ? (e.value as List).join(', ') : e.value.toString();
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
            const SizedBox(height: 12),
            if (flow.isUnderstanding)
              const UnderstandingIndicator(label: 'Understanding…')
            else
              ElevatedButton(
                onPressed: _submitText,
                child: const Text('Continue'),
              ),
          ],

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  isVoice ? Icons.keyboard : Icons.mic,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  if (_listening) {
                    _gnaniService.stopListening();
                    setState(() {
                      _listening = false;
                      _micReady = false;
                    });
                  }
                  flow.toggleInputMode();
                },
                tooltip: isVoice ? 'Type instead' : 'Speak instead',
              ),
              Text(
                isVoice ? 'Type instead' : 'Speak instead',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          TextButton(
            onPressed: _skipToQuestions,
            child: const Text('Skip — just show me options'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'mealType': return 'Meal';
      case 'flavours': return 'Flavour';
      case 'method': return 'How';
      case 'ingredients': return 'With';
      case 'cookTime': return 'Time';
      case 'cuisine': return 'Cuisine';
      case 'vibe': return 'Vibe';
      default: return key;
    }
  }
}

// ── Live Nudge Bar (Sarvam LLM powered) ───────────────────────────────────────

class _LiveNudgeBar extends StatelessWidget {
  const _LiveNudgeBar({
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
            _HintChip('"Something spicy for dinner"'),
            _HintChip('"Quick lunch, maybe order in"'),
            _HintChip('"Cook with paneer and rice"'),
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

// ── Step Wrapper ────────────────────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  const _StepWrapper({
    required this.question,
    required this.child,
    this.onSkip,
    this.onNext,
    this.canAdvance = true,
  });

  final String question;
  final Widget child;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final bool canAdvance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: child)),
          if (onNext != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canAdvance ? onNext : null,
              child: const Text('Next'),
            ),
          ],
          if (onSkip != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSkip, child: const Text('Not sure — just show me')),
          ],
        ],
      ),
    );
  }
}

// ── Meal Type Step ────────────────────────────────────────────────────────────

class _MealTypeStep extends StatelessWidget {
  const _MealTypeStep({super.key});

  static const _options = [
    ('Breakfast', Icons.wb_sunny_outlined),
    ('Lunch', Icons.restaurant_outlined),
    ('Snack', Icons.bakery_dining_outlined),
    ('Dinner', Icons.nights_stay_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: 'What meal is this?',
      onSkip: () => flow.setMealType('meal'),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: _options.map((opt) => _BigTile(
          icon: opt.$2,
          label: opt.$1,
          onTap: () => flow.setMealType(opt.$1.toLowerCase()),
        )).toList(),
      ),
    );
  }
}

// ── Flavour Step ──────────────────────────────────────────────────────────────

class _FlavourStep extends StatefulWidget {
  const _FlavourStep({super.key});

  @override
  State<_FlavourStep> createState() => _FlavourStepState();
}

class _FlavourStepState extends State<_FlavourStep> {
  final Set<String> _selected = {};
  static const _options = ['Spicy', 'Light', 'Comforting', 'Sweet'];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: 'What flavours are you feeling?',
      onNext: _selected.isNotEmpty ? () => flow.setFlavours(_selected.toList()) : null,
      canAdvance: _selected.isNotEmpty,
      onSkip: () => flow.setFlavours(['anything']),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: _options.map((o) => _SelectableTile(
          label: o,
          selected: _selected.contains(o),
          onTap: () => setState(() {
            _selected.contains(o) ? _selected.remove(o) : _selected.add(o);
          }),
        )).toList(),
      ),
    );
  }
}

// ── Method Step ───────────────────────────────────────────────────────────────

class _MethodStep extends StatelessWidget {
  const _MethodStep({super.key});

  static const _options = [
    ('Cook at home', Icons.kitchen_outlined, 'cook'),
    ('Order in', Icons.delivery_dining_outlined, 'order'),
    ('Dine out', Icons.storefront_outlined, 'dine'),
    ('Surprise me', Icons.casino_outlined, 'cook'),
  ];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: 'How are you getting food?',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: _options.map((opt) => _BigTile(
          icon: opt.$2,
          label: opt.$1,
          onTap: () => flow.setMethod(opt.$3),
        )).toList(),
      ),
    );
  }
}

// ── Ingredients Step (Gnani voice) ────────────────────────────────────────────

class _IngredientsStep extends StatefulWidget {
  const _IngredientsStep({super.key});

  @override
  State<_IngredientsStep> createState() => _IngredientsStepState();
}

class _IngredientsStepState extends State<_IngredientsStep> {
  bool _voiceMode = true;
  bool _listening = false; // session active (getting ready or streaming)
  bool _micReady = false; // stream connected — safe for the user to talk
  String _transcript = '';
  final _textController = TextEditingController();

  final GnaniSpeechService _gnaniService = GnaniSpeechService();
  bool _gnaniAvailable = false;

  @override
  void initState() {
    super.initState();
    final flow = context.read<EatFlowProvider>();
    _voiceMode = flow.isVoiceMode;
    _initGnani();
  }

  Future<void> _initGnani() async {
    _gnaniAvailable = _gnaniService.isAvailable;

    _gnaniService.onTranscript = (transcript, isFinal) {
      if (!mounted) return;
      setState(() => _transcript = transcript);

      if (isFinal && transcript.isNotEmpty) {
        setState(() => _listening = false);
        context.read<EatFlowProvider>().setIngredientsFromText(transcript);
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
        SnackBar(content: Text('Voice error: $error. Switched to text.')),
      );
    };

    _gnaniService.onStatus = (status) {
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
    _textController.dispose();
    _gnaniService.dispose();
    super.dispose();
  }

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
    _gnaniService.stopListening();
    setState(() {
      _listening = false;
      _micReady = false;
    });
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<EatFlowProvider>().setIngredientsFromText(text);
  }

  @override
  Widget build(BuildContext context) {
    final understanding = context.watch<EatFlowProvider>().isUnderstanding;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'What do you have to cook with?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Condiments & basic spices are assumed.\nJust say what you have — any way you like.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Spacer(),

          if (_voiceMode) ...[
            if (_transcript.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(_transcript, style: Theme.of(context).textTheme.bodyLarge),
              ),

            if (understanding)
              const UnderstandingIndicator(label: 'Picking out your ingredients…')
            else
              Center(
                child: VoiceMicButton(
                  phase: !_listening
                      ? MicPhase.idle
                      : _micReady
                          ? MicPhase.listening
                          : MicPhase.connecting,
                  onTap: _listening ? _stopListening : _startListening,
                  idleLabel: 'Tap to speak your ingredients',
                  listeningLabel: 'Speak now — list your ingredients',
                ),
              ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., "some leftover rice, 2 eggs and half a cabbage"',
                  hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (understanding)
              const UnderstandingIndicator(label: 'Picking out your ingredients…')
            else
              ElevatedButton(
                onPressed: _submitText,
                child: const Text('Continue'),
              ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _voiceMode ? Icons.keyboard : Icons.mic,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  if (_listening) {
                    _gnaniService.stopListening();
                    _listening = false;
                    _micReady = false;
                  }
                  setState(() => _voiceMode = !_voiceMode);
                },
              ),
              Text(
                _voiceMode ? 'Type instead' : 'Speak instead',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.read<EatFlowProvider>().setIngredients([]),
            child: const Text('Skip — use whatever\'s common'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Cook Time Step ────────────────────────────────────────────────────────────

class _CookTimeStep extends StatelessWidget {
  const _CookTimeStep({super.key});

  static const _options = ['15 minutes', '30 minutes', '45 minutes', 'Any time'];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: 'How much time do you have?',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: _options.map((o) => _SelectableTile(
          label: o,
          selected: false,
          onTap: () => flow.setCookTime(o),
        )).toList(),
      ),
    );
  }
}

// ── Cuisine Step ──────────────────────────────────────────────────────────────

class _CuisineStep extends StatelessWidget {
  const _CuisineStep({super.key});

  static const _options = ['North Indian', 'South Indian', 'Chinese', 'Any'];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: 'Any cuisine preference?',
      onSkip: () => flow.setCuisine('any'),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: _options.map((o) => _SelectableTile(
          label: o,
          selected: false,
          onTap: () => flow.setCuisine(o),
        )).toList(),
      ),
    );
  }
}

// ── Vibe Step ─────────────────────────────────────────────────────────────────

class _VibeStep extends StatelessWidget {
  const _VibeStep({super.key});

  static const _options = [
    ('Casual', Icons.table_restaurant_outlined),
    ('Quick bite', Icons.flash_on_outlined),
    ('Something special', Icons.star_outline),
    ('Surprise me', Icons.casino_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EatFlowProvider>();
    return _StepWrapper(
      question: "What's the vibe?",
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: _options.map((opt) => _BigTile(
          icon: opt.$2,
          label: opt.$1,
          onTap: () => flow.setVibe(opt.$1.toLowerCase()),
        )).toList(),
      ),
    );
  }
}

// ── Loading Step ──────────────────────────────────────────────────────────────

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DoodleLoader(
        title: 'Finding your picks…',
        subtitle: 'Matching your mood, your diet and what you have',
      ),
    );
  }
}

// ── Shared UI Pieces ──────────────────────────────────────────────────────────

class _BigTile extends StatelessWidget {
  const _BigTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.ink, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: selected ? 2.5 : 2),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_circle, color: AppColors.ink, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
