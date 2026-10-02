import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MicPhase { idle, connecting, listening }

/// Mic button with an explicit "getting ready" phase, so users don't start
/// talking before the speech stream is connected and lose their first words.
class VoiceMicButton extends StatefulWidget {
  final MicPhase phase;
  final VoidCallback onTap;
  final String idleLabel;
  final String listeningLabel;

  const VoiceMicButton({
    super.key,
    required this.phase,
    required this.onTap,
    this.idleLabel = 'Tap to speak',
    this.listeningLabel = 'Speak now — tap to finish',
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );
  // One-shot "go" pop when the stream becomes ready.
  late final AnimationController _pop = AnimationController(
    duration: const Duration(milliseconds: 350),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.phase == MicPhase.listening) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VoiceMicButton old) {
    super.didUpdateWidget(old);
    if (widget.phase == old.phase) return;
    if (widget.phase == MicPhase.listening) {
      _pulse.repeat(reverse: true);
      _pop.forward(from: 0);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final listening = phase == MicPhase.listening;
    final connecting = phase == MicPhase.connecting;

    final label = switch (phase) {
      MicPhase.idle => widget.idleLabel,
      MicPhase.connecting => 'Getting ready… hold on a sec',
      MicPhase.listening => widget.listeningLabel,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _pop]),
            builder: (_, __) {
              final pulseScale = listening ? 0.9 + 0.1 * Curves.easeInOut.transform(_pulse.value) : 1.0;
              final popScale = 1.0 + 0.18 * Curves.easeOut.transform(1 - _pop.value) * (_pop.isAnimating ? 1 : 0);
              return Transform.scale(
                scale: pulseScale * popScale,
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (connecting)
                        const SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: listening ? AppColors.primary : AppColors.primaryLight,
                          shape: BoxShape.circle,
                          boxShadow: listening
                              ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)]
                              : const [],
                        ),
                        child: Icon(
                          listening ? Icons.stop : connecting ? Icons.hourglass_top : Icons.mic,
                          color: listening ? Colors.white : AppColors.primary.withOpacity(connecting ? 0.6 : 1),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(phase),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: listening ? AppColors.primary : AppColors.textMuted,
              fontWeight: listening ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
