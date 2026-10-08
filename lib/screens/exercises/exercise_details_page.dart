import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/exercise_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/exercise_card.dart';

// da el Exercise Details screen + simple timer
class ExerciseDetailsPage extends StatelessWidget {
  final ExerciseModel exercise;
  const ExerciseDetailsPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          NetworkImageBox(
            url: e.imageUrl,
            fallbackIcon: exerciseIcon(e.category),
            height: 200,
            width: double.infinity,
            radius: 26,
          ),
          const SizedBox(height: 16),
          Text(e.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(text: e.category, color: AppColors.primary),
              StatusBadge(text: e.difficulty, color: const Color(0xFF7C8CF8)),
              StatusBadge(text: '${e.durationMinutes} min', color: AppColors.success),
              StatusBadge(text: '${e.calories} kcal', color: const Color(0xFFF08A5D)),
            ],
          ),
          const SectionHeader(title: 'Description'),
          Text(e.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SectionHeader(title: 'Instructions'),
          ..._instructions(e).map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step)),
                  ],
                ),
              )),
          if (e.videoUrl != null && e.videoUrl!.isNotEmpty)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(e.videoUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Watch video'),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ExerciseTimerPage(exercise: e))),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Exercise'),
          ),
        ],
      ),
    );
  }

  // instructions 3amma (static) 3shan el user ytmrn b amaan
  List<String> _instructions(ExerciseModel e) => [
        'Warm up for 3-5 minutes before you start.',
        'Do ${e.name} for about ${e.durationMinutes} minutes at a comfortable pace.',
        'Keep good form and breathe steadily.',
        'Stop if you feel pain, dizziness or shortness of breath.',
        'Cool down and stretch when you finish.',
      ];
}

// da el simple exercise timer (Start / Pause / Reset)
class ExerciseTimerPage extends StatefulWidget {
  final ExerciseModel exercise;
  const ExerciseTimerPage({super.key, required this.exercise});

  @override
  State<ExerciseTimerPage> createState() => _ExerciseTimerPageState();
}

class _ExerciseTimerPageState extends State<ExerciseTimerPage> {
  static const _presets = [30, 60, 300];
  int _total = 30;
  int _left = 30;
  Timer? _timer;

  bool get _running => _timer?.isActive ?? false;

  @override
  void dispose() {
    _timer?.cancel(); // lazem nw2f el timer 3shan mafish memory leak
    super.dispose();
  }

  void _start() {
    if (_left == 0) _left = _total;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
        showSnack(context, 'Great job! Exercise finished');
      } else {
        setState(() => _left--);
      }
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    setState(() => _left = _total);
  }

  void _setPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _total = seconds;
      _left = seconds;
    });
  }

  String get _text => '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.6;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: SoftBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in _presets)
                        ChoiceChip(
                          label: Text(p < 60 ? '$p sec' : '${p ~/ 60} min'),
                          selected: _total == p,
                          showCheckmark: false,
                          labelStyle: TextStyle(color: _total == p ? Colors.white : AppColors.text),
                          onSelected: (_) => _setPreset(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // da'era el progress zay el heart ring f el sora
                  SizedBox(
                    width: size.clamp(180, 280),
                    height: size.clamp(180, 280),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: _total == 0 ? 0 : _left / _total,
                          strokeWidth: 14,
                          backgroundColor: AppColors.peach,
                          color: AppColors.primary,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(_text, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'reset',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        onPressed: _reset,
                        child: const Icon(Icons.replay_rounded),
                      ),
                      const SizedBox(width: 24),
                      FloatingActionButton.large(
                        heroTag: 'play',
                        onPressed: _running ? _pause : _start,
                        child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_running ? 'Pause' : 'Start', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
