import 'model_helpers.dart';

// da el model beta3 el gym / fitness club
class GymModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final double rating;
  final String? imageUrl;

  const GymModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.phone,
    required this.rating,
    this.imageUrl,
  });

  factory GymModel.fromMap(Map<String, dynamic> map) => GymModel(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        address: (map['address'] ?? '') as String,
        latitude: toDoubleOrNull(map['latitude']),
        longitude: toDoubleOrNull(map['longitude']),
        phone: map['phone'] as String?,
        rating: toDouble(map['rating']),
        imageUrl: map['image_url'] as String?,
      );
}

// da el model beta3 bakat el eshterak (el admin by8yr as3arha)
class GymPlanModel {
  final String id;
  final String gymId;
  final String name;
  final int durationMonths;
  final double price;
  final String description;

  const GymPlanModel({
    required this.id,
    required this.gymId,
    required this.name,
    required this.durationMonths,
    required this.price,
    required this.description,
  });

  factory GymPlanModel.fromMap(Map<String, dynamic> map) => GymPlanModel(
        id: map['id'] as String,
        gymId: map['gym_id'] as String,
        name: (map['name'] ?? '') as String,
        durationMonths: toInt(map['duration_months']),
        price: toDouble(map['price']),
        description: (map['description'] ?? '') as String,
      );
}

// da el model beta3 eshterak el patient f gym
class GymSubscriptionModel {
  final String id;
  final String gymName;
  final String planName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  const GymSubscriptionModel({
    required this.id,
    required this.gymName,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory GymSubscriptionModel.fromMap(Map<String, dynamic> map) => GymSubscriptionModel(
        id: map['id'] as String,
        gymName: (asMap(map['gyms'])['name'] ?? '') as String,
        planName: (map['plan_name'] ?? '') as String,
        price: toDouble(map['price']),
        startDate: toDate(map['start_date']),
        endDate: toDate(map['end_date']),
        status: (map['status'] ?? 'active') as String,
      );

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
}
