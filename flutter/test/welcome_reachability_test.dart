import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/theme/app_theme.dart';

/// "Continue as guest" is the only way into the app without an account, so it
/// must be on screen without scrolling — on a short phone and at a large system
/// font, not just on the one device this was developed against.
///
/// The screen itself pulls in Supabase and Provider, so this pumps the same
/// pinned-footer structure rather than the real widget. What is under test is
/// the layout contract: a scrollable region that yields, and a footer that does
/// not.
Widget _welcomeSkeleton() {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(height: 148, color: Colors.green),
                  const SizedBox(height: 24),
                  Container(height: 300, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(height: 140, color: Colors.white),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                const Text('Or try it without an account'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Continue as guest'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: _welcomeSkeleton(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('welcome: guest entry is reachable without scrolling', () {
    void expectFullyOnScreen(WidgetTester tester, Size size) {
      final box = tester.getRect(find.text('Continue as guest'));
      expect(
        box.bottom,
        lessThanOrEqualTo(size.height),
        reason: 'guest CTA bottom ${box.bottom} exceeds screen ${size.height}',
      );
      expect(box.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    }

    for (final size in const [
      Size(360, 800), // the dev device
      Size(360, 640), // short phone
      Size(320, 568), // smallest phone still in use
    ]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pump(tester, size: size);
        expectFullyOnScreen(tester, size);
      });
    }

    testWidgets('at 360x640 with 1.5x system text', (tester) async {
      const size = Size(360, 640);
      await _pump(tester, size: size, textScale: 1.5);
      expectFullyOnScreen(tester, size);
    });

    testWidgets('the content above it still scrolls when it overflows',
        (tester) async {
      const size = Size(320, 568);
      await _pump(tester, size: size);
      // The footer holds its place while the region above it scrolls.
      final before = tester.getRect(find.text('Continue as guest'));
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Continue as guest')), before);
    });
  });
}
