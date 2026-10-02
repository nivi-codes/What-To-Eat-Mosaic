import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/doodles.dart';
import '../widgets/w2e_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: DoodleWallpaper(opacity: 0.22, seed: 3)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  const Center(child: W2ELogo(size: 176)),
                  const SizedBox(height: 28),
                  Text(
                    'WhatToEat',
                    textAlign: TextAlign.center,
                    style: AppTheme.font(size: 46, weight: FontWeight.w900, color: AppColors.ink, spacing: -1.8),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.turmeric,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: Text('Decide in 60 seconds',
                          style: AppTheme.font(size: 15, weight: FontWeight.w800, color: AppColors.ink)),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text("Let's get to know your taste", textAlign: TextAlign.center, style: text.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    "A quick setup so suggestions fit how you actually eat.",
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () => context.push('/onboarding'),
                    child: const Text('Get started'),
                  ),
                  const Spacer(flex: 1),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
