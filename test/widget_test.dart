import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mshro3eltkhrog/core/theme/app_theme.dart';
import 'package:mshro3eltkhrog/screens/auth/setup_required_page.dart';
import 'package:mshro3eltkhrog/screens/medical/eye_check_page.dart';
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

  // test lel eye check: sora 7amra lazem tdy e7merar 3aly, w sora beda la2
  test('eye check detects redness', () {
    final red = img.Image(width: 100, height: 100)..clear(img.ColorRgb8(220, 40, 40));
    final white = img.Image(width: 100, height: 100)..clear(img.ColorRgb8(240, 240, 240));
    final redResult = analyzeEye(img.encodePng(red), []);
    final whiteResult = analyzeEye(img.encodePng(white), []);
    expect(redResult.level, 2);
    expect(whiteResult.level, 0);
    expect(analyzeEye(img.encodePng(white), ['Eye pain']).urgent, true);
  });
}
