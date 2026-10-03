import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/preferences_provider.dart';
import '../providers/meal_log_provider.dart';
import '../providers/eat_flow_provider.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final logs = context.watch<MealLogProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Me')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekly balance card
            _WeeklyCard(logs: logs),
            const SizedBox(height: 16),

            // Nudge
            if (logs.nudgeMessage != null) ...[
              _NudgeCard(message: logs.nudgeMessage!),
              const SizedBox(height: 16),
            ],

            // My taste profile
            _SectionCard(
              title: 'My taste profile',
              trailing: TextButton(
                onPressed: () => context.push('/onboarding/options'),
                child: const Text('Edit'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TasteRow('Eating style', _capitalize(prefs.preferences.dietaryType)),
                  if (prefs.preferences.cuisines.isNotEmpty)
                    _TasteRow('Cuisines', prefs.preferences.cuisines.take(3).join(', ')),
                  if (prefs.preferences.flavours.isNotEmpty)
                    _TasteRow('Flavours', prefs.preferences.flavours.take(3).map(_capitalize).join(', ')),
                  if (prefs.preferences.avoidances.isNotEmpty)
                    _TasteRow('Avoids', prefs.preferences.avoidances.take(3).map(_capitalize).join(', ')),
                  _TasteRow('Healthy pref', _healthyLabel(prefs.preferences.healthyPreference)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Meal history
            _SectionCard(
              title: 'Meal history',
              child: logs.logs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Meals appear here once you start logging.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : Column(
                      children: logs.logs.take(5).map((log) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                log.imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: AppColors.tagBg,
                                  child: const Icon(Icons.restaurant, size: 20, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log.recipeTitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
                                  Text('${log.nutrition.calories} kcal · ${log.variant}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              _formatTime(log.loggedAt),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Settings
            _SectionCard(
              title: 'Settings',
              child: Column(
                children: [
                  _SettingsTile(icon: Icons.notifications_outlined, label: 'Nudges & reminders', onTap: () {}),
                  _SettingsTile(icon: Icons.refresh_outlined, label: 'Redo onboarding', onTap: () {
                    prefs.resetOnboarding();
                    context.go('/welcome');
                  }),
                  _SettingsTile(icon: Icons.help_outline, label: 'Help', onTap: () {}),
                  _SettingsTile(icon: Icons.info_outline, label: 'About WhatToEat', onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('-', ' ')}';

  String _healthyLabel(String v) {
    switch (v) {
      case 'healthy_first': return 'Healthy options first';
      case 'regular_first': return 'Regular options first';
      default: return 'Show me both';
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:$m $amPm';
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.logs});
  final MealLogProvider logs;

  @override
  Widget build(BuildContext context) {
    final week = logs.weekSummary;
    final maxCal = week.map((d) => d['calories'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly balance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Approximate calories per day', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: week.map((day) {
                final cal = day['calories'] as int;
                final h = (cal / maxCal * 64).clamp(8.0, 64.0);
                final isToday = day['day'] == _todayShort();
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day['day'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _todayShort() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.primary, fontSize: 14)),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    final log = context.read<MealLogProvider>();
                    context.read<EatFlowProvider>().startLightMeal(
                          mealType: log.nextMeal,
                          preferences: context.read<PreferencesProvider>().preferences,
                          heavyMeals: log.heavyToday.map((l) => l.recipeTitle).toList(),
                        );
                    context.push('/eat/flow');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text('Show light ${context.read<MealLogProvider>().nextMeal} picks →', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TasteRow extends StatelessWidget {
  const _TasteRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
