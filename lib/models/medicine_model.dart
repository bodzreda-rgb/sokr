import 'model_helpers.dart';

// da el model beta3 el dawa
class MedicineModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final bool prescriptionRequired;

  const MedicineModel({
    this.id = '',
    required this.pharmacyId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    required this.prescriptionRequired,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) => MedicineModel(
        id: map['id'] as String,
        pharmacyId: map['pharmacy_id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        category: (map['category'] ?? 'General') as String,
        price: toDouble(map['price']),
        stockQuantity: toInt(map['stock_quantity']),
        imageUrl: map['image_url'] as String?,
        prescriptionRequired: (map['prescription_required'] ?? false) as bool,
      );

  // el map elly bnb3to lel insert/update
  Map<String, dynamic> toMap() => {
        'pharmacy_id': pharmacyId,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'stock_quantity': stockQuantity,
        'image_url': imageUrl,
        'prescription_required': prescriptionRequired,
      };
}
