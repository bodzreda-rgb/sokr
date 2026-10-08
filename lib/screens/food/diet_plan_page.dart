import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/diet_model.dart';
import '../../services/doctor_portal_service.dart';
import '../../services/food_service.dart';
import '../../widgets/common_widgets.dart';
import 'food_details_page.dart';

// card beta3 diet plan wa7ed (byt3rd lel patient w lel doctor)
class DietPlanCard extends StatelessWidget {
  final DietPlanModel plan;
  final VoidCallback? onDelete; // lel doctor bas

  const DietPlanCard({super.key, required this.plan, this.onDelete});

  // lama el patient ydos 3la akla, bnfta7 tafaseelha (w y2dar y3mlha order)
  Future<void> _openFood(BuildContext context, DietItem item) async {
    final restaurant = await FoodService.getRestaurantById(item.food.restaurantId);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailsPage(food: item.food, restaurant: restaurant)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: Icons.restaurant_menu_rounded, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${plan.doctorName} • ${formatDate(plan.createdAt)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: AppColors.error)),
            ],
          ),
          if (plan.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.notes),
          ],
          // el akl mtrateb b el wagba
          for (final meal in DietPlanModel.meals)
            if (plan.items.any((i) => i.meal == meal)) ...[
              const SizedBox(height: 10),
              Text(meal, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              for (final item in plan.items.where((i) => i.meal == meal))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ramen_dining_rounded, color: Color(0xFFF08A5D)),
                  title: Text(item.food.name),
                  subtitle: Text('${item.food.calories} kcal • ${item.food.protein}g protein'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openFood(context, item),
                ),
            ],
          const Divider(),
          Text('Total: ${plan.totalCalories} kcal per day',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// el patient byshof el diet plans elly el doctor 3amalha
class MyDietPlanPage extends StatelessWidget {
  const MyDietPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Diet Plan')),
      body: AsyncView<List<DietPlanModel>>(
        future: DoctorPortalService.getMyDietPlans(),
        builder: (plans) {
          if (plans.isEmpty) {
            return const EmptyView(
              message: 'No diet plan yet.\nBook a doctor and they can make one for you.',
              icon: Icons.restaurant_menu_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: plans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => DietPlanCard(plan: plans[i]),
          );
        },
      ),
    );
  }
}
