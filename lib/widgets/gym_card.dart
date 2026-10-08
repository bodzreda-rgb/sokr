import 'package:flutter/material.dart';

import '../models/gym_model.dart';
import '../services/location_service.dart';
import 'common_widgets.dart';

// da card beta3 el gym
class GymCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback onView;
  final VoidCallback onExercises;

  const GymCard({super.key, required this.gym, required this.onView, required this.onExercises});

  @override
  Widget build(BuildContext context) {
    final distance = LocationService.distanceText(gym.latitude, gym.longitude);
    return AppCard(
      onTap: onView,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkImageBox(
            url: gym.imageUrl,
            fallbackIcon: Icons.fitness_center_rounded,
            height: 110,
            width: double.infinity,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(gym.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              RatingText(rating: gym.rating),
            ],
          ),
          const SizedBox(height: 6),
          InfoLine(
            icon: Icons.location_on_outlined,
            text: distance == null ? gym.address : '${gym.address} • $distance',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onView, child: const Text('View Gym'))),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: onExercises,
                  child: const Text('Exercises'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
