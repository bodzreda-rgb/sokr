import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/pharmacy_model.dart';
import '../services/location_service.dart';
import 'common_widgets.dart';

// da card beta3 el saydaleya
class PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onTap;
  const PharmacyCard({super.key, required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final distance = LocationService.distanceText(pharmacy.latitude, pharmacy.longitude);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          NetworkImageBox(
            url: pharmacy.imageUrl,
            fallbackIcon: Icons.local_pharmacy_rounded,
            height: 72,
            width: 72,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(pharmacy.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    StatusBadge(
                      text: pharmacy.isOpen ? 'Open' : 'Closed',
                      color: pharmacy.isOpen ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InfoLine(icon: Icons.location_on_outlined, text: pharmacy.address),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingText(rating: pharmacy.rating),
                    if (distance != null) ...[
                      const SizedBox(width: 12),
                      Text(distance, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
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
