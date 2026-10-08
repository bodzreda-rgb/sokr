import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/exercise_model.dart';
import 'common_widgets.dart';

// icon le kol category tamareen (badal sowar copyrighted)
IconData exerciseIcon(String category) => switch (category) {
      'Cardio' => Icons.directions_bike_rounded,
      'Strength' => Icons.fitness_center_rounded,
      'Stretching' => Icons.accessibility_new_rounded,
      'Yoga' => Icons.self_improvement_rounded,
      'Walking' => Icons.directions_walk_rounded,
      'Running' => Icons.directions_run_rounded,
      _ => Icons.home_rounded,
    };

// da card beta3 el tamreen
class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  const ExerciseCard({super.key, required this.exercise, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          NetworkImageBox(
            url: exercise.imageUrl,
            fallbackIcon: exerciseIcon(exercise.category),
            height: 76,
            width: 76,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${exercise.category} • ${exercise.difficulty}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    StatusBadge(text: '${exercise.durationMinutes} min', color: AppColors.primary),
                    StatusBadge(text: '${exercise.calories} kcal', color: const Color(0xFFF08A5D)),
                  ],
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
