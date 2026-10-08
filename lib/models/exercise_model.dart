import 'model_helpers.dart';

// da el model beta3 el tamreen
class ExerciseModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int calories;
  final String? imageUrl;
  final String? videoUrl;

  const ExerciseModel({
    this.id = '',
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.calories,
    this.imageUrl,
    this.videoUrl,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map) => ExerciseModel(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        category: (map['category'] ?? 'Home Workout') as String,
        difficulty: (map['difficulty'] ?? 'Beginner') as String,
        durationMinutes: toInt(map['duration_minutes']),
        calories: toInt(map['calories']),
        imageUrl: map['image_url'] as String?,
        videoUrl: map['video_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'calories': calories,
        'image_url': imageUrl,
        'video_url': videoUrl,
      };

  static const categories = [
    'Cardio',
    'Strength',
    'Stretching',
    'Yoga',
    'Walking',
    'Running',
    'Home Workout',
  ];
  static const difficulties = ['Beginner', 'Intermediate', 'Advanced'];
}
