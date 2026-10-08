import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

// ======================================================
// Health Information (badal el chat pages el adema:
// "Required insulin" / "Food Profile" / "Eyes Problem")
// da static information bas - MAFISH AI hena.
// ======================================================

class HealthTopic {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> points;
  const HealthTopic(this.title, this.subtitle, this.icon, this.color, this.points);
}

// el topics el adema etnaqalet hena ka general information
const healthTopics = [
  HealthTopic('Insulin & Diabetes', 'Understanding insulin basics', Icons.vaccines_rounded, AppColors.primary, [
    'Insulin is a hormone that helps glucose move from the blood into your cells.',
    'The type and dose of insulin is decided ONLY by your doctor. Never change your dose on your own.',
    'Keep a log of your blood sugar readings and share it with your doctor.',
    'Learn the signs of low blood sugar: shaking, sweating, dizziness, confusion.',
    'Store insulin as described on the package and check expiry dates.',
  ]),
  HealthTopic('Blood Glucose', 'Track your sugar levels', Icons.monitor_heart_rounded, AppColors.error, [
    'Record readings in the Health Status screen to see your trend.',
    'Measure at the times your doctor recommends (e.g. fasting or after meals).',
    'Contact a doctor if readings are often outside the range they gave you.',
  ]),
  HealthTopic('Food Profile', 'Balanced plates & carbs', Icons.restaurant_rounded, Color(0xFFF08A5D), [
    'Fill half your plate with vegetables, a quarter with protein and a quarter with whole grains.',
    'Prefer whole foods and limit sugary drinks and highly processed snacks.',
    'Check calories, protein, carbs and fats in the Healthy Food section.',
    'A dietitian can build a meal plan that fits your health condition.',
  ]),
  HealthTopic('Eye Care', 'Watch for vision changes', Icons.visibility_rounded, Color(0xFF7C8CF8), [
    'People with diabetes should have a regular eye exam as advised by their doctor.',
    'See a doctor quickly if you notice blurred vision, floaters, or dark spots.',
    'Controlling blood sugar and blood pressure helps protect your eyes.',
  ]),
  HealthTopic('Exercise', 'Stay active safely', Icons.directions_run_rounded, AppColors.success, [
    'Aim for regular moderate activity like brisk walking.',
    'Start slowly and warm up before exercise.',
    'Ask your doctor before starting a new program if you have a medical condition.',
  ]),
  HealthTopic('Foot Care', 'Prevent sores and infection', Icons.health_and_safety_rounded, AppColors.warning, [
    'Check your feet daily for cuts, blisters or redness.',
    'Wear comfortable, well-fitting shoes.',
    'Visit a doctor if a wound does not heal.',
  ]),
];

class HealthInfoPage extends StatefulWidget {
  const HealthInfoPage({super.key});

  @override
  State<HealthInfoPage> createState() => _HealthInfoPageState();
}

class _HealthInfoPageState extends State<HealthInfoPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // hena bn3ml search basit f el topics (keyword match, msh AI)
    final q = _query.toLowerCase();
    final topics = healthTopics
        .where((t) =>
            q.isEmpty ||
            t.title.toLowerCase().contains(q) ||
            t.points.any((p) => p.toLowerCase().contains(q)))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Health Information')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppSearchBar(hint: 'Search insulin, food, eyes...', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 16),
          const DisclaimerCard(),
          const SizedBox(height: 16),
          if (topics.isEmpty) const EmptyView(message: 'No topics found'),
          for (final t in topics) ...[
            AppCard(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => HealthTopicPage(topic: t))),
              child: Row(
                children: [
                  IconTile(icon: t.icon, color: t.color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(t.subtitle,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// tafaseel topic wa7ed
class HealthTopicPage extends StatelessWidget {
  final HealthTopic topic;
  const HealthTopicPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: IconTile(icon: topic.icon, color: topic.color, size: 80)),
          const SizedBox(height: 20),
          for (final p in topic.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: topic.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const DisclaimerCard(),
        ],
      ),
    );
  }
}
