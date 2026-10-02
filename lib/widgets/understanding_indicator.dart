import 'package:flutter/material.dart';
import 'doodles.dart';

/// Shown while the LLM interprets what the user said/typed.
class UnderstandingIndicator extends StatelessWidget {
  const UnderstandingIndicator({super.key, this.label = 'Understanding what you said…'});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DoodleLoader.compact(title: label),
      );
}
