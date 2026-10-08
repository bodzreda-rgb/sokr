import 'package:flutter/material.dart';

import '../../models/exercise_model.dart';
import '../../services/fitness_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/exercise_card.dart';
import 'exercise_details_page.dart';
import 'gyms_page.dart';

// da el Exercises tab: feh 2 views (Exercises / Gyms)
class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  bool _showGyms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_showGyms ? 'Gyms & Clubs' : 'Exercises')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Exercises'), icon: Icon(Icons.directions_run_rounded)),
                  ButtonSegment(value: true, label: Text('Gyms'), icon: Icon(Icons.fitness_center_rounded)),
                ],
                selected: {_showGyms},
                onSelectionChanged: (s) => setState(() => _showGyms = s.first),
              ),
            ),
          ),
          Expanded(child: _showGyms ? const GymsView() : const _ExercisesList()),
        ],
      ),
    );
  }
}

class _ExercisesList extends StatefulWidget {
  const _ExercisesList();

  @override
  State<_ExercisesList> createState() => _ExercisesListState();
}

class _ExercisesListState extends State<_ExercisesList> {
  late Future<List<ExerciseModel>> _future;
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _future = FitnessService.getExercises();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<ExerciseModel>>(
      future: _future,
      onRetry: () => setState(() => _future = FitnessService.getExercises()),
      builder: (all) {
        // hena bn3ml filter bel category w el search
        final q = _query.toLowerCase();
        final list = all
            .where((e) =>
                (q.isEmpty || e.name.toLowerCase().contains(q)) &&
                (_category == 'All' || e.category == _category))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            AppSearchBar(hint: 'Search exercises...', onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 12),
            CategoryChips(
              items: const ['All', ...ExerciseModel.categories],
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty) const EmptyView(message: 'No exercises found', icon: Icons.directions_run_rounded),
            for (final e in list) ...[
              ExerciseCard(
                exercise: e,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ExerciseDetailsPage(exercise: e))),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
