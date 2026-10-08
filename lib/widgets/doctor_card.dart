import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/doctor_model.dart';
import '../services/location_service.dart';
import 'common_widgets.dart';

// da card beta3 doctor (zay el "Find Doctors" f el sora)
class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onViewProfile;
  final VoidCallback onBook;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onViewProfile,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final distance = LocationService.distanceText(doctor.latitude, doctor.longitude);
    return AppCard(
      onTap: onViewProfile,
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(name: doctor.name, imageUrl: doctor.avatarUrl, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(doctor.specialization,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RatingText(rating: doctor.rating),
                        Text('${doctor.yearsExperience}+ Years Exp.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (distance != null)
                          Text(distance,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(doctor.consultationPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  StatusBadge(
                    text: doctor.isAvailable ? 'Available' : 'Busy',
                    color: doctor.isAvailable ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: doctor.isAvailable ? onBook : null,
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
