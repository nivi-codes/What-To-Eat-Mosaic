import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Moodboard card: ink-outlined surface sitting on an offset colour block.
class OffsetCard extends StatelessWidget {
  const OffsetCard({
    super.key,
    required this.child,
    this.blockColor = AppColors.lime,
    this.color = AppColors.surface,
    this.offset = 8,
    this.radius = 24,
    this.onTap,
  });

  final Widget child;
  final Color blockColor;
  final Color color;
  final double offset;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    const border = BorderSide(color: AppColors.ink, width: 2.5);
    return Padding(
      padding: EdgeInsets.only(right: offset, bottom: offset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: offset,
            top: offset,
            right: -offset,
            bottom: -offset,
            child: DecoratedBox(
              decoration: BoxDecoration(color: blockColor, borderRadius: shape, border: Border.fromBorderSide(border)),
            ),
          ),
          Material(
            color: color,
            shape: RoundedRectangleBorder(borderRadius: shape, side: border),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: child),
          ),
        ],
      ),
    );
  }
}

/// Outlined pill tag ("20 min", "High protein").
class OutlinePill extends StatelessWidget {
  const OutlinePill(this.text, {super.key, this.fill = AppColors.surface});
  final String text;
  final Color fill;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
        child: Text(text, style: AppTheme.font(size: 12, weight: FontWeight.w700, color: AppColors.ink)),
      );
}
