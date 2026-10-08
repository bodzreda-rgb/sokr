import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/food_model.dart';
import 'common_widgets.dart';

// da card beta3 el akla (calories + macros)
class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onOrder;
  final Widget? trailing; // lel restaurant dashboard

  const FoodCard({super.key, required this.food, this.onTap, this.onOrder, this.trailing});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageBox(
            url: food.imageUrl,
            fallbackIcon: Icons.ramen_dining_rounded,
            height: 84,
            width: 84,
            color: const Color(0xFFF08A5D),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    MacroChip(label: '${food.calories} kcal', color: const Color(0xFFF08A5D)),
                    MacroChip(label: '${food.protein}g P', color: AppColors.primary),
                    MacroChip(label: '${food.carbs}g C', color: const Color(0xFF7C8CF8)),
                    MacroChip(label: '${food.fats}g F', color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(money(food.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                    trailing ??
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: onOrder,
                            child: const Text('Order'),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const MacroChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
