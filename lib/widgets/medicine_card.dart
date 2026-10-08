import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/medicine_model.dart';
import 'common_widgets.dart';

// da card beta3 el dawa (fe add to cart, aw edit/delete lel pharmacist)
class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final VoidCallback? onAdd;
  final Widget? trailing; // lel dashboard (edit / delete buttons)

  const MedicineCard({super.key, required this.medicine, this.onAdd, this.trailing});

  @override
  Widget build(BuildContext context) {
    final inStock = medicine.stockQuantity > 0;
    return AppCard(
      child: Row(
        children: [
          NetworkImageBox(
            url: medicine.imageUrl,
            fallbackIcon: Icons.medication_rounded,
            height: 70,
            width: 70,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(medicine.category,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusBadge(
                      text: inStock ? 'Stock: ${medicine.stockQuantity}' : 'Out of stock',
                      color: inStock ? AppColors.success : AppColors.error,
                    ),
                    if (medicine.prescriptionRequired)
                      const StatusBadge(text: 'Prescription required', color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(medicine.price),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 6),
              trailing ??
                  IconButton.filled(
                    onPressed: inStock ? onAdd : null,
                    tooltip: 'Add to Cart',
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
