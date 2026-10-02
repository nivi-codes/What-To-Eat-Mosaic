import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/preferences_provider.dart';

class OnboardingOptionsScreen extends StatefulWidget {
  const OnboardingOptionsScreen({super.key});

  @override
  State<OnboardingOptionsScreen> createState() => _OnboardingOptionsScreenState();
}

class _OnboardingOptionsScreenState extends State<OnboardingOptionsScreen> {
  int _step = 0;

  String? _dietaryType;
  final Set<String> _cuisines = {};
  final Set<String> _flavours = {};
  final Set<String> _avoidances = {};
  String? _healthyPreference;

  static const _steps = [
    'How do you eat?',
    'Which cuisines do you love?',
    'What flavours do you usually like?',
    'Anything you avoid?',
    'How do you feel about healthy food?',
  ];

  static const _dietaryOptions = ['Vegetarian', 'Vegan', 'Eggetarian', 'Non-vegetarian'];
  static const _cuisineOptions = [
    'North Indian', 'South Indian', 'Street food', 'Chinese',
    'Italian', 'Continental', 'Mughlai', 'Gujarati', 'Bengali', 'Maharashtrian',
  ];
  static const _flavourOptions = [
    'Spicy', 'Savoury', 'Tangy', 'Sweet', 'Soothing',
    'Creamy', 'Smoky', 'Crunchy', 'Fresh', 'Rich',
  ];
  static const _avoidanceOptions = [
    'Dairy', 'Gluten', 'Nuts', 'Eggs', 'Onion & Garlic', 'Seafood', 'None',
  ];
  static const _healthyOptions = [
    'Healthy options first',
    'Regular options first',
    'Show me both',
  ];

  void _next() {
    final prefs = context.read<PreferencesProvider>();
    if (_step == 0 && _dietaryType != null) {
      prefs.setDietaryType(_dietaryType!.toLowerCase().replaceAll(' ', '-'));
    } else if (_step == 1) {
      prefs.setCuisines(_cuisines.toList());
    } else if (_step == 2) {
      prefs.setFlavours(_flavours.map((f) => f.toLowerCase()).toList());
    } else if (_step == 3) {
      prefs.setAvoidances(_avoidances.map((a) => a.toLowerCase()).toList());
    } else if (_step == 4 && _healthyPreference != null) {
      final map = {
        'Healthy options first': 'healthy_first',
        'Regular options first': 'regular_first',
        'Show me both': 'both',
      };
      prefs.setHealthyPreference(map[_healthyPreference] ?? 'both');
      prefs.completeOnboarding();
      context.go('/onboarding/done');
      return;
    }

    if (_step < 4) setState(() => _step++);
  }

  bool get _canAdvance {
    switch (_step) {
      case 0: return _dietaryType != null;
      case 4: return _healthyPreference != null;
      default: return true; // multi-select steps are skippable
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/welcome'),
              ),
        title: Text('${_step + 1} of ${_steps.length}'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_step + 1) / _steps.length,
              backgroundColor: AppColors.cardBorder,
              color: AppColors.primary,
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _steps[_step],
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _canAdvance ? _next : null,
                    child: Text(_step == 4 ? 'Done' : 'Next'),
                  ),
                  if (_step > 0 && _step < 4) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _next,
                      child: const Text('Skip'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _SingleSelectGrid(
          options: _dietaryOptions,
          selected: _dietaryType,
          onSelect: (v) => setState(() { _dietaryType = v; _next(); }),
        );
      case 1:
        return _MultiSelectWrap(
          options: _cuisineOptions,
          selected: _cuisines,
          onToggle: (v) => setState(() {
            _cuisines.contains(v) ? _cuisines.remove(v) : _cuisines.add(v);
          }),
        );
      case 2:
        return _MultiSelectWrap(
          options: _flavourOptions,
          selected: _flavours,
          onToggle: (v) => setState(() {
            _flavours.contains(v) ? _flavours.remove(v) : _flavours.add(v);
          }),
        );
      case 3:
        return _MultiSelectWrap(
          options: _avoidanceOptions,
          selected: _avoidances,
          onToggle: (v) => setState(() {
            _avoidances.contains(v) ? _avoidances.remove(v) : _avoidances.add(v);
          }),
        );
      case 4:
        return _SingleSelectGrid(
          options: _healthyOptions,
          selected: _healthyPreference,
          onSelect: (v) => setState(() { _healthyPreference = v; }),
          columns: 1,
        );
      default:
        return const SizedBox();
    }
  }
}

class _SingleSelectGrid extends StatelessWidget {
  const _SingleSelectGrid({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.columns = 2,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final isSelected = o == selected;
        return InkWell(
          onTap: () => onSelect(o),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  o,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiSelectWrap extends StatelessWidget {
  const _MultiSelectWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (_) => onToggle(o),
          selectedColor: AppColors.primaryLight,
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        );
      }).toList(),
    );
  }
}
