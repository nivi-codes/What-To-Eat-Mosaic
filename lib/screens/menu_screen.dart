import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/menu.dart';
import '../models/suggestion.dart';
import '../providers/eat_flow_provider.dart';
import '../services/web_links.dart';
import '../theme/app_theme.dart';

/// "View menu" for a dine-out suggestion: LLM-suggested dishes for the restaurant,
/// generated on the fly (usually prefetched while the suggestions were shown).
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.id, this.name, this.cuisine});

  final String id;
  // Fallbacks for when the suggestion is no longer in the current session (e.g. from Saved).
  final String? name;
  final String? cuisine;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<List<MenuSection>?>? _pending;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EatFlowProvider>();
    Suggestion? suggestion;
    for (final s in flow.suggestions) {
      if (s.recipeId == widget.id) suggestion = s;
    }
    final name = suggestion?.title ?? widget.name;
    if (name == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: const Center(child: Text('Restaurant not found')),
      );
    }
    final cuisine = suggestion != null ? suggestion.subtitle.split('·').first.trim() : widget.cuisine;
    _pending ??= flow.menuFor(widget.id, name, cuisine: cuisine);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                suggestion?.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 60),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  if (suggestion != null) ...[
                    const SizedBox(height: 4),
                    Text(suggestion.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (suggestion != null && suggestion.healthHighlights.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestion.healthHighlights
                          .map((h) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.tagBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(h,
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => openInNewTab(mapsSearchUrl(name)),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Find on Google Maps'),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('What to order', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Popular picks for a place like this — AI-suggested, prices approximate.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<MenuSection>?>(
              future: _pending,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 14),
                        Text('Pulling up the menu…', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                final sections = snap.data;
                if (sections == null || sections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Text("Couldn't load the menu right now.", style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() => _pending = null),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final s in sections) _MenuSectionView(section: s)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: suggestion != null
          ? FloatingActionButton.extended(
              onPressed: () {
                context.read<EatFlowProvider>().reset();
                context.go('/eat');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enjoy your meal at $name!'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.directions_walk, color: Colors.white),
              label: const Text("Let's go here", style: TextStyle(color: Colors.white)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _MenuSectionView extends StatelessWidget {
  const _MenuSectionView({required this.section});
  final MenuSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 3), child: _DietMark(diet: item.diet)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: item.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          if (item.diet == 'vegan' || item.diet == 'eggetarian')
                            TextSpan(
                              text: item.diet == 'vegan' ? '  VEGAN' : '  EGG',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _DietMark.colorFor(item.diet)),
                            ),
                        ])),
                        if (item.description.isNotEmpty)
                          Text(item.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (item.price > 0)
                    Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Indian-menu convention: green for veg/vegan, amber for egg, red for non-veg.
class _DietMark extends StatelessWidget {
  const _DietMark({required this.diet});
  final String diet;

  static Color colorFor(String diet) => switch (diet) {
        'non-vegetarian' => const Color(0xFFC62828),
        'eggetarian' => const Color(0xFFE08A00),
        _ => const Color(0xFF2E7D32),
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(diet);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(2)),
      child: Center(
        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}
