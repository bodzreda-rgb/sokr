import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/exercise_model.dart';
import '../../models/gym_model.dart';
import '../../services/fitness_service.dart';
import '../../services/location_service.dart';
import '../../services/medical_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/gym_card.dart';
import 'exercise_details_page.dart';

// list el gyms (bttzhar gowa el Exercises tab)
class GymsView extends StatefulWidget {
  const GymsView({super.key});

  @override
  State<GymsView> createState() => _GymsViewState();
}

class _GymsViewState extends State<GymsView> {
  late Future<List<GymModel>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // hena bngeb el gyms w nrtbhom bel masafa
  Future<List<GymModel>> _load() async {
    final gyms = await FitnessService.getGyms();
    await LocationService.getPosition();
    return LocationService.sortByDistance(gyms, (g) => g.latitude, (g) => g.longitude);
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<GymModel>>(
      future: _future,
      onRetry: () => setState(() => _future = _load()),
      builder: (all) {
        final q = _query.toLowerCase();
        final list = all
            .where((g) => q.isEmpty || g.name.toLowerCase().contains(q) || g.address.toLowerCase().contains(q))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AppSearchBar(hint: 'Search gyms...', onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 14),
            if (list.isEmpty) const EmptyView(message: 'No gyms found', icon: Icons.fitness_center_rounded),
            for (final g in list) ...[
              GymCard(
                gym: g,
                onView: () => _open(GymDetailsPage(gym: g)),
                onExercises: () => _open(GymDetailsPage(gym: g)),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

// tafaseel el gym + el tamareen elly fe
class GymDetailsPage extends StatefulWidget {
  final GymModel gym;
  const GymDetailsPage({super.key, required this.gym});

  @override
  State<GymDetailsPage> createState() => _GymDetailsPageState();
}

class _GymDetailsPageState extends State<GymDetailsPage> {
  late Future<List<ExerciseModel>> _future;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _future = FitnessService.getGymExercises(widget.gym.id);
    MedicalService.isFavorite('gym', widget.gym.id).then((v) {
      if (mounted) setState(() => _isFavorite = v);
    }).catchError((_) {});
  }

  Future<void> _toggleFavorite() async {
    try {
      final v = await MedicalService.toggleFavorite('gym', widget.gym.id);
      if (mounted) setState(() => _isFavorite = v);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not update favorites', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gym;
    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          NetworkImageBox(url: g.imageUrl, fallbackIcon: Icons.fitness_center_rounded, height: 170, width: double.infinity),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text(g.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              RatingText(rating: g.rating),
            ],
          ),
          const SizedBox(height: 6),
          Text(g.description, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          InfoLine(icon: Icons.location_on_rounded, text: g.address),
          if (g.phone != null) InfoLine(icon: Icons.phone_rounded, text: g.phone!),
          const SectionHeader(title: 'Exercises in this gym'),
          AsyncView<List<ExerciseModel>>(
            future: _future,
            onRetry: () => setState(() => _future = FitnessService.getGymExercises(g.id)),
            builder: (list) {
              if (list.isEmpty) return const EmptyView(message: 'No exercises added yet');
              return Column(
                children: [
                  for (final e in list) ...[
                    ExerciseCard(
                      exercise: e,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => ExerciseDetailsPage(exercise: e))),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
