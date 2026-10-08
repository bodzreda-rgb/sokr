import 'package:flutter/material.dart';

import '../../widgets/common_widgets.dart';

// el screen di btzhar bas law el developer lessa ma7atsh el Supabase URL w el key
class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(height: 90),
                    SizedBox(height: 16),
                    Text('Supabase is not configured',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 10),
                    Text(
                      'Open lib/core/supabase_config.dart and add your Supabase URL and anon (public) key, '
                      'then run supabase/supabase_schema.sql in the Supabase SQL Editor.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
