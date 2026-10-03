import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/meal_log_provider.dart';
import '../providers/eat_flow_provider.dart';
import '../providers/preferences_provider.dart';
import '../data/mock_data.dart';
import '../widgets/doodles.dart';
import '../widgets/offset_card.dart';
import '../widgets/w2e_logo.dart';

class EatHomeScreen extends StatelessWidget {
  const EatHomeScreen({super.key});

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // "Tuesday, 8:40 pm"
  String _now() {
    final n = DateTime.now();
    final h = n.hour % 12 == 0 ? 12 : n.hour % 12;
    return '${_days[n.weekday - 1]}, $h:${n.minute.toString().padLeft(2, '0')} ${n.hour < 12 ? 'am' : 'pm'}';
  }

  String _headline() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'What are we eating this morning?';
    if (hour >= 11 && hour < 17) return 'What are we eating today?';
    return 'What are we eating tonight?';
  }

  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<MealLogProvider>();
    final nudge = logProvider.nudgeMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        const Positioned.fill(child: DoodleWallpaper()),
        SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + Search ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _now(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_headline(), style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const W2ELogo(size: 64),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Start Session Bar ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OffsetCard(
                  onTap: () {
                    context.read<EatFlowProvider>().startSession(
                      voiceMode: true,
                      preferences: context.read<PreferencesProvider>().preferences,
                    );
                    context.push('/eat/flow');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(color: AppColors.cobalt, shape: BoxShape.circle),
                          child: const Icon(Icons.mic, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tell me what you're craving", style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                'Speak or type · decide in 60 seconds',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: AppColors.ink, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Nudge ──────────────────────────────────────────────
              if (nudge != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NudgeCard(message: nudge),
                ),
                const SizedBox(height: 16),
              ],

              // ── Quick Categories ───────────────────────────────────
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.quickCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final cat = MockData.quickCategories[i];
                    return _CategoryPill(
                      doodle: cat['doodle'] as String,
                      label: cat['label'] as String,
                      onTap: () {
                        context.read<EatFlowProvider>().startSession(
                      voiceMode: false,
                      preferences: context.read<PreferencesProvider>().preferences,
                    );
                        context.push('/eat/flow');
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Today's Balance (compact) ──────────────────────────
              if (logProvider.todayLogs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CompactBalanceCard(logProvider: logProvider),
                ),
                const SizedBox(height: 24),
              ],

              // ── Trending Recipes ───────────────────────────────────
              _SectionHeader(title: 'Trending Now', onSeeAll: () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.trendingRecipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final r = MockData.trendingRecipes[i];
                    return _RecipeCard(
                      title: r['title'] as String,
                      subtitle: r['subtitle'] as String,
                      imageUrl: r['imageUrl'] as String,
                      calories: r['calories'] as int,
                      tags: List<String>.from(r['tags'] as List),
                      onTap: () => context.push('/eat/recipe/${r['recipeId']}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Celebrity Chef Recipes ─────────────────────────────
              _SectionHeader(title: 'Celebrity Chef Recipes', onSeeAll: () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.celebrityChefRecipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final r = MockData.celebrityChefRecipes[i];
                    return _ChefRecipeCard(
                      title: r['title'] as String,
                      chef: r['chef'] as String,
                      imageUrl: r['imageUrl'] as String,
                      cookTime: r['cookTime'] as String,
                      rating: (r['rating'] as num).toDouble(),
                      onTap: () => context.push('/eat/recipe/${r['recipeId']}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Star Recipes ───────────────────────────────────────
              _SectionHeader(title: 'Star Recipes', onSeeAll: () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.starRecipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final r = MockData.starRecipes[i];
                    return _StarRecipeCard(
                      title: r['title'] as String,
                      rating: (r['rating'] as num).toDouble(),
                      reviews: r['reviews'] as int,
                      imageUrl: r['imageUrl'] as String,
                      badge: r['badge'] as String,
                      onTap: () => context.push('/eat/recipe/${r['recipeId']}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Featured Restaurants ───────────────────────────────
              _SectionHeader(title: 'Popular Restaurants', onSeeAll: () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.featuredRestaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final r = MockData.featuredRestaurants[i];
                    return _RestaurantCard(
                      name: r['name'] as String,
                      cuisine: r['cuisine'] as String,
                      rating: (r['rating'] as num).toDouble(),
                      deliveryTime: r['deliveryTime'] as String,
                      priceRange: r['priceRange'] as String,
                      imageUrl: r['imageUrl'] as String,
                      onTap: () {},
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent Meals ───────────────────────────────────────
              if (logProvider.logs.isNotEmpty) ...[
                _SectionHeader(title: 'Recent Meals', onSeeAll: () {}),
                const SizedBox(height: 12),
                ...logProvider.logs.take(3).map((log) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _RecentMealTile(
                    title: log.recipeTitle,
                    calories: '${log.nutrition.calories} kcal',
                    time: _formatTime(log.loggedAt),
                    imageUrl: log.imageUrl,
                  ),
                )),
              ],

              const SizedBox(height: 100), // bottom nav clearance
            ],
          ),
        ),
      ),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:$m $amPm';
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all →',
              style: AppTheme.font(size: 13, weight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Pill ───────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.doodle, required this.label, required this.onTap});
  final String doodle;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(Doodles.asset(doodle), width: 60, height: 60),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Compact Balance Card ────────────────────────────────────────────────────

class _CompactBalanceCard extends StatelessWidget {
  const _CompactBalanceCard({required this.logProvider});
  final MealLogProvider logProvider;

  @override
  Widget build(BuildContext context) {
    final kcal = logProvider.todayCalories;
    final meals = logProvider.todayLogs.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.ink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$kcal kcal today · $meals ${meals == 1 ? 'meal' : 'meals'} logged',
              style: AppTheme.font(size: 14, weight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink, size: 20),
        ],
      ),
    );
  }
}

// ── Nudge Card ──────────────────────────────────────────────────────────────

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final log = context.read<MealLogProvider>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: AppColors.chilli, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AppTheme.font(size: 15, weight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    context.read<EatFlowProvider>().startLightMeal(
                          mealType: log.nextMeal,
                          preferences: context.read<PreferencesProvider>().preferences,
                          heavyMeals: log.heavyToday.map((l) => l.recipeTitle).toList(),
                        );
                    context.push('/eat/flow');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Show light ${log.nextMeal} picks', style: AppTheme.font(size: 13, weight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recipe Card (horizontal scroll) ─────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.calories,
    required this.tags,
    required this.onTap,
  });

  final String title, subtitle, imageUrl;
  final int calories;
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 100,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100, width: 160,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.restaurant, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  OutlinePill('~$calories kcal', fill: AppColors.turmeric),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chef Recipe Card ────────────────────────────────────────────────────────

class _ChefRecipeCard extends StatelessWidget {
  const _ChefRecipeCard({
    required this.title,
    required this.chef,
    required this.imageUrl,
    required this.cookTime,
    required this.rating,
    required this.onTap,
  });

  final String title, chef, imageUrl, cookTime;
  final double rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110, width: 180,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.restaurant, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by $chef',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.turmeric, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        '$rating',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule, color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        cookTime,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star Recipe Card ────────────────────────────────────────────────────────

class _StarRecipeCard extends StatelessWidget {
  const _StarRecipeCard({
    required this.title,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.badge,
    required this.onTap,
  });

  final String title, imageUrl, badge;
  final double rating;
  final int reviews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100, width: 200,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.restaurant, color: AppColors.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.turmeric, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            '$rating',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($reviews)',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.turmeric,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: AppTheme.font(size: 11, weight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restaurant Card ─────────────────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.priceRange,
    required this.imageUrl,
    required this.onTap,
  });

  final String name, cuisine, deliveryTime, priceRange, imageUrl;
  final double rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110, width: 190,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.storefront, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cuisine,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$rating',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$deliveryTime · $priceRange',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Meal Tile ────────────────────────────────────────────────────────

class _RecentMealTile extends StatelessWidget {
  const _RecentMealTile({
    required this.title,
    required this.calories,
    required this.time,
    required this.imageUrl,
  });

  final String title, calories, time, imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44, height: 44,
                color: AppColors.tagBg,
                child: const Icon(Icons.restaurant, color: AppColors.textMuted, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$calories · $time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
