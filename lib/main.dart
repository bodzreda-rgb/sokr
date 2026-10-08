import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/setup_required_page.dart';
import 'services/supabase_service.dart';

// da awel 7aga btshta8al f el app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // law el credentials mawgoda bn3ml connection m3 Supabase
  if (SupabaseConfig.isConfigured) {
    await SupabaseService.init();
  }
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthcare',
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      // law Supabase msh configured bnwareh el user ezay y3mlo badal crash
      home: SupabaseConfig.isConfigured ? const AuthGate() : const SetupRequiredPage(),
    );
  }
}

// 3shan el scroll yshta8al bel mouse kman (web / desktop)
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
