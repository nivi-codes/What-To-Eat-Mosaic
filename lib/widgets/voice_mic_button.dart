import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MicPhase { idle, connecting, listening }

/// Mic button with an explicit "getting ready" phase, so users don't start
/// talking before the speech stream is connected and lose their first words.
/// Moodboard style: cobalt mic inside double cobalt rings.
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
              final wave = listening ? Curves.easeInOut.transform(_pulse.value) : 0.0;
              final popScale = 1.0 + 0.15 * Curves.easeOut.transform(1 - _pop.value) * (_pop.isAnimating ? 1 : 0);
              return Transform.scale(
                scale: popScale,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Double rings; they breathe outward while listening.
                      _Ring(size: 104 + 8 * wave, opacity: connecting ? 0.25 : 1),
                      _Ring(size: 90 + 4 * wave, opacity: connecting ? 0.25 : 1),
                      if (connecting)
                        const SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.cobalt),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: connecting ? const Color(0xFFDCE2FF) : AppColors.cobalt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          listening ? Icons.stop_rounded : connecting ? Icons.hourglass_top : Icons.mic,
                          color: connecting ? AppColors.cobalt : Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(phase),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: listening ? AppColors.cobalt : AppColors.textMuted,
                  fontWeight: listening ? FontWeight.w800 : FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cobalt.withOpacity(opacity), width: 2),
        ),
      );
}
