import 'food_model.dart';
import 'model_helpers.dart';

// da el model beta3 el diet plan elly el doctor bey3mlo lel patient
class DietPlanModel {
  final String id;
  final String patientId;
  final String title;
  final String notes;
  final String doctorName;
  final DateTime createdAt;
  final List<DietItem> items;

  const DietPlanModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.notes,
    required this.doctorName,
    required this.createdAt,
    required this.items,
  });

  // el query: select('*, doctors(full_name), diet_plan_items(*, food_items(*))')
  factory DietPlanModel.fromMap(Map<String, dynamic> map) => DietPlanModel(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        title: (map['title'] ?? '') as String,
        notes: (map['notes'] ?? '') as String,
        doctorName: (asMap(map['doctors'])['full_name'] ?? '') as String,
        createdAt: toDate(map['created_at']),
        items: ((map['diet_plan_items'] as List?) ?? [])
            .map((e) => asMap(e))
            .where((e) => e['food_items'] != null)
            .map((e) => DietItem(
                  meal: (e['meal'] ?? 'Lunch') as String,
                  food: FoodModel.fromMap(asMap(e['food_items'])),
                ))
            .toList(),
      );

  int get totalCalories => items.fold(0, (s, i) => s + i.food.calories);

  static const meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
}

class DietItem {
  final String meal;
  final FoodModel food;
  const DietItem({required this.meal, required this.food});
}
