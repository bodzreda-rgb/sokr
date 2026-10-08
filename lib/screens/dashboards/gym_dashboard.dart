import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/exercise_model.dart';
import '../../models/gym_model.dart';
import '../../services/fitness_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/exercise_card.dart';
import '../exercises/exercise_details_page.dart';
import 'dashboard_common.dart';

// da el Gym Dashboard (lw el role = gym)
class GymDashboard extends StatefulWidget {
  const GymDashboard({super.key});

  @override
  State<GymDashboard> createState() => _GymDashboardState();
}

class _GymDashboardState extends State<GymDashboard> {
  int _tab = 0;
  late Future<GymModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = FitnessService.getMyGym();
  }

  void _reload() => setState(() => _future = FitnessService.getMyGym());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: AsyncView<GymModel?>(
            future: _future,
            onRetry: _reload,
            builder: (gym) {
              if (gym == null) return const EmptyView(message: 'Gym not found');
              return IndexedStack(
                index: _tab,
                children: [
                  _GymExercisesTab(gym: gym),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Gym Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      StoreProfileForm(
                        showOpenSwitch: false,
                        initial: {
                          'name': gym.name,
                          'description': gym.description,
                          'address': gym.address,
                          'phone': gym.phone,
                          'image_url': gym.imageUrl,
                          'latitude': gym.latitude,
                          'longitude': gym.longitude,
                        },
                        onSave: (v) async {
                          await FitnessService.updateGym(gym.id, v);
                          _reload();
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center_rounded), label: 'Exercises'),
          NavigationDestination(icon: Icon(Icons.store_rounded), label: 'Gym Profile'),
        ],
      ),
    );
  }
}

class _GymExercisesTab extends StatefulWidget {
  final GymModel gym;
  const _GymExercisesTab({required this.gym});

  @override
  State<_GymExercisesTab> createState() => _GymExercisesTabState();
}

class _GymExercisesTabState extends State<_GymExercisesTab> {
  late Future<List<ExerciseModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FitnessService.getGymExercises(widget.gym.id);
  }

  void _reload() => setState(() => _future = FitnessService.getGymExercises(widget.gym.id));

  // form wa7ed lel add w el edit
  Future<void> _openForm([ExerciseModel? e]) async {
    final values = await showFormSheet(
      context,
      title: e == null ? 'Add Exercise' : 'Edit Exercise',
      fields: const {
        'name': 'Name',
        'category': 'Category',
        'difficulty': 'Difficulty',
        'description': 'Description',
        'duration_minutes': 'Duration (minutes)',
        'calories': 'Calories',
        'video_url': 'Video URL (optional)',
      },
      initial: e == null
          ? const {}
          : {
              'name': e.name,
              'category': e.category,
              'difficulty': e.difficulty,
              'description': e.description,
              'duration_minutes': '${e.durationMinutes}',
              'calories': '${e.calories}',
              'video_url': e.videoUrl ?? '',
            },
      numeric: const {'duration_minutes', 'calories'},
      optional: const {'description', 'video_url'},
      dropdowns: const {'category': ExerciseModel.categories, 'difficulty': ExerciseModel.difficulties},
    );
    if (values == null || !mounted) return;
    final exercise = ExerciseModel(
      name: values['name']!,
      category: values['category']!,
      difficulty: values['difficulty']!,
      description: values['description']!,
      durationMinutes: int.parse(values['duration_minutes']!.split('.').first),
      calories: int.parse(values['calories']!.split('.').first),
      videoUrl: values['video_url']!.isEmpty ? null : values['video_url'],
    );
    final ok = await runAction(
      context,
      () => e == null
          ? FitnessService.addGymExercise(widget.gym.id, exercise)
          : FitnessService.updateExercise(e.id, exercise.toMap()),
      e == null ? 'Exercise added' : 'Exercise updated',
    );
    if (ok) _reload();
  }

  Future<void> _remove(ExerciseModel e) async {
    if (!await confirmDialog(context, 'Remove exercise', 'Remove ${e.name} from your gym?')) return;
    if (!mounted) return;
    final ok = await runAction(context, () => FitnessService.removeGymExercise(widget.gym.id, e), 'Exercise removed');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: AsyncView<List<ExerciseModel>>(
        future: _future,
        onRetry: _reload,
        builder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            DashboardHeader(subtitle: widget.gym.name),
            const SizedBox(height: 18),
            StatsGrid(cards: [
              StatCard(icon: Icons.fitness_center_rounded, label: 'Exercises', value: '${list.length}'),
              StatCard(icon: Icons.star_rounded, label: 'Rating', value: widget.gym.rating.toStringAsFixed(1), color: AppColors.warning),
            ]),
            const SectionHeader(title: 'Gym Exercises'),
            if (list.isEmpty) const EmptyView(message: 'No exercises yet. Tap + to add.'),
            for (final e in list) ...[
              ExerciseCard(
                exercise: e,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailsPage(exercise: e))),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? _openForm(e) : _remove(e),
                  itemBuilder: (_) => [
                    // el tamareen el 3amma (seed) mynf3sh yt3mlha edit, bs momken teshelha men el gym
                    if (e.createdBy != null) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
