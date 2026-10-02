import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown while the LLM interprets what the user said/typed.
class UnderstandingIndicator extends StatelessWidget {
  const UnderstandingIndicator({super.key, this.label = 'Understanding what you said…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
