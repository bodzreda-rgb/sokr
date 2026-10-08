import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/restaurant_model.dart';
import '../services/location_service.dart';
import 'common_widgets.dart';

// da card beta3 el mat3am el healthy
class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;
  const RestaurantCard({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final distance = LocationService.distanceText(restaurant.latitude, restaurant.longitude);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          NetworkImageBox(
            url: restaurant.imageUrl,
            fallbackIcon: Icons.restaurant_rounded,
            height: 80,
            width: 80,
            color: const Color(0xFFF08A5D),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    StatusBadge(
                      text: restaurant.isOpen ? 'Open' : 'Closed',
                      color: restaurant.isOpen ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(restaurant.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                InfoLine(
                  icon: Icons.location_on_outlined,
                  text: distance == null ? restaurant.address : '${restaurant.address} • $distance',
                ),
                const SizedBox(height: 4),
                RatingText(rating: restaurant.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
