import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mshro3eltkhrog/core/theme/app_theme.dart';
import 'package:mshro3eltkhrog/screens/auth/setup_required_page.dart';
import 'package:mshro3eltkhrog/widgets/common_widgets.dart';

void main() {
  // test basit: el setup screen btzhar law Supabase msh configured
  testWidgets('Setup page renders', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SetupRequiredPage()));
    expect(find.text('Supabase is not configured'), findsOneWidget);
  });

  // test lel helpers beta3t el formatting
  test('formatTime converts 24h to 12h', () {
    expect(formatTime('14:30:00'), '02:30 PM');
    expect(formatTime('09:00'), '09:00 AM');
    expect(prettyStatus('out_for_delivery'), 'Out For Delivery');
  });
}
