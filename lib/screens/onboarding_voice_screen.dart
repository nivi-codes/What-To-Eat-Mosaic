import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/preferences_provider.dart';

class OnboardingVoiceScreen extends StatefulWidget {
  const OnboardingVoiceScreen({super.key});

  @override
  State<OnboardingVoiceScreen> createState() => _OnboardingVoiceScreenState();
}

class _OnboardingVoiceScreenState extends State<OnboardingVoiceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _listening = false;
  String _transcript = '';
  Timer? _autoTimer;
  int _countdown = 5;
  Timer? _countdownTimer;

  static const _simulatedTranscript =
      "I'm vegetarian, love South Indian and street food. Usually prefer spicy and tangy flavours. I like healthy options shown first.";

  final _nudges = [
    "Do you eat meat, eggs or neither?",
    "Which cuisines do you love?",
    "Anything you avoid?",
    "Do you like to see healthy options first?",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startListening() {
    setState(() {
      _listening = true;
      _transcript = '';
      _countdown = 5;
    });

    // Simulate typing transcript
    int charIndex = 0;
    Timer.periodic(const Duration(milliseconds: 60), (t) {
      if (!mounted) { t.cancel(); return; }
      if (charIndex < _simulatedTranscript.length) {
        setState(() => _transcript = _simulatedTranscript.substring(0, charIndex + 1));
        charIndex++;
      } else {
        t.cancel();
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _finishOnboarding();
      }
    });
  }

  void _finishOnboarding() {
    final prefs = context.read<PreferencesProvider>();
    prefs.setDietaryType('vegetarian');
    prefs.setCuisines(['South Indian', 'Street food']);
    prefs.setFlavours(['spicy', 'tangy']);
    prefs.setHealthyPreference('healthy_first');
    prefs.completeOnboarding();
    context.go('/onboarding/done');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Voice setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Tell me about yourself',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Speak freely — what you eat, what you love,\nanything you avoid.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Nudge bubbles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _nudges.map((n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(n, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                )).toList(),
              ),
              const Spacer(),

              // Transcript area
              if (_transcript.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heard:', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(_transcript, style: Theme.of(context).textTheme.bodyLarge),
                      if (_listening && _countdown < 5) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Done in $_countdown...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Mic button
              Center(
                child: GestureDetector(
                  onTap: _listening ? _finishOnboarding : _startListening,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: _listening ? _pulse.value : 1.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _listening ? AppColors.primary : AppColors.primaryLight,
                            shape: BoxShape.circle,
                            boxShadow: _listening
                                ? [BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  )]
                                : [],
                          ),
                          child: Icon(
                            _listening ? Icons.stop : Icons.mic,
                            color: _listening ? Colors.white : AppColors.primary,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _listening ? 'Tap to finish' : 'Tap to start speaking',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              if (!_listening)
                TextButton(
                  onPressed: () {
                    context.read<PreferencesProvider>().setInputMode('tap');
                    context.go('/onboarding/options');
                  },
                  child: const Text('Switch to tap mode instead'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
