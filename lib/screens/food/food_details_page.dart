import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/food_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/cart_service.dart';
import '../../widgets/common_widgets.dart';
import '../pharmacy/cart_page.dart';

// hena bn-add el akla lel food cart (function wa7da bnst5dmha f aktar men makan)
void addFoodToCart(BuildContext context, FoodModel food, RestaurantModel? restaurant) {
  if (restaurant == null) return;
  if (!restaurant.isOpen) {
    showSnack(context, '${restaurant.name} is closed now', error: true);
    return;
  }
  final added = CartService.food.add(
    restaurant.id,
    restaurant.name,
    CartItem(id: food.id, name: food.name, price: food.price),
  );
  showSnack(
    context,
    added ? '${food.name} added to cart' : 'Your cart has items from another restaurant. Empty it first.',
    error: !added,
  );
}

// da el Food Details screen (nutrition facts)
class FoodDetailsPage extends StatelessWidget {
  final FoodModel food;
  final RestaurantModel? restaurant;
  const FoodDetailsPage({super.key, required this.food, this.restaurant});

  @override
  Widget build(BuildContext context) {
    final f = food;
    return Scaffold(
      appBar: AppBar(title: Text(f.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          NetworkImageBox(
            url: f.imageUrl,
            fallbackIcon: Icons.ramen_dining_rounded,
            height: 200,
            width: double.infinity,
            radius: 26,
            color: const Color(0xFFF08A5D),
          ),
          const SizedBox(height: 16),
          Text(f.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (restaurant != null)
            Text('by ${restaurant!.name}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          StatusBadge(text: f.category, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(f.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SectionHeader(title: 'Nutrition Facts'),
          // 4 cards lel macros
          Row(
            children: [
              _macro('Calories', '${f.calories}', 'kcal', const Color(0xFFF08A5D)),
              const SizedBox(width: 8),
              _macro('Protein', '${f.protein}', 'g', AppColors.primary),
              const SizedBox(width: 8),
              _macro('Carbs', '${f.carbs}', 'g', const Color(0xFF7C8CF8)),
              const SizedBox(width: 8),
              _macro('Fats', '${f.fats}', 'g', AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(money(f.price),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: restaurant == null ? null : () => addFoodToCart(context, f, restaurant),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Order'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage(kind: CartKind.food))),
            child: const Text('Go to Cart'),
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, String value, String unit, Color color) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              ),
              Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              FittedBox(child: Text(label, style: const TextStyle(fontSize: 12))),
            ],
          ),
        ),
      );
}

