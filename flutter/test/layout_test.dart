import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantdoc/core/theme/app_theme.dart';
import 'package:plantdoc/core/constants/app_assets.dart';
import 'package:plantdoc/core/widgets/bottom_nav.dart';
import 'package:plantdoc/core/widgets/photo_band.dart';
import 'package:plantdoc/core/widgets/diagnosis_widgets.dart';
import 'package:plantdoc/core/widgets/scan_activity_tile.dart';
import 'package:plantdoc/core/widgets/state_views.dart';

/// Layout guards for the fixed-height chrome.
///
/// These components carry hard heights (the nav bar, the risk track, the
/// history row), which is exactly where a small screen or a large system font
/// causes a RenderFlex overflow. `tester.takeException()` surfaces any overflow
/// as a test failure.
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(375, 640),
  double textScale = 1.0,
  double bottomInset = 0,
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
          padding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('bottom navigation', () {
    Widget nav() => PlantDocBottomNav(
          currentIndex: 0,
          onTap: (_) {},
          onScanTap: () {},
        );

    testWidgets('fits a 375px phone', (tester) async {
      await _pumpAt(tester, nav());
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 2x system text without overflowing', (tester) async {
      await _pumpAt(tester, nav(), textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow 320px phone', (tester) async {
      await _pumpAt(tester, nav(), size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('every destination is reachable and labelled', (tester) async {
      final tapped = <int>[];
      var scanTapped = false;
      await _pumpAt(
        tester,
        PlantDocBottomNav(
          currentIndex: 0,
          onTap: tapped.add,
          onScanTap: () => scanTapped = true,
        ),
      );

      for (final label in ['Home', 'History', 'Plants', 'Profile']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      await tester.tap(find.text('History'));
      await tester.tap(find.bySemanticsLabel('Scan a plant').first);
      expect(tapped, contains(1));
      expect(scanTapped, isTrue);
    });
  });

  group('ConfidenceIndicator', () {
    testWidgets('shows a whole percent, never raw float precision',
        (tester) async {
      await _pumpAt(tester, const ConfidenceIndicator(percent: 87));
      expect(find.text('87%'), findsOneWidget);
      expect(find.text('AI confidence'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 0 and 100 without overflow', (tester) async {
      await _pumpAt(tester, const ConfidenceIndicator(percent: 0));
      expect(tester.takeException(), isNull);
      await _pumpAt(tester, const ConfidenceIndicator(percent: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('RiskLevelBar', () {
    testWidgets('names the level in words, not colour alone', (tester) async {
      for (final (level, label) in [
        ('low', 'Low risk'),
        ('medium', 'Medium risk'),
        ('high', 'High risk'),
      ]) {
        await _pumpAt(tester, RiskLevelBar(level: level));
        expect(find.text(label), findsOneWidget, reason: level);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('falls back to medium for an unknown level', (tester) async {
      await _pumpAt(tester, const RiskLevelBar(level: 'unheard-of'));
      expect(find.text('Medium risk'), findsOneWidget);
    });
  });

  group('HealthStatusBadge', () {
    testWidgets('states the status in text as well as colour', (tester) async {
      // Case-insensitive: the badge renders small caps, but what is being
      // asserted is that the status is spelled out at all, not how.
      for (final (status, label) in [
        (HealthStatus.healthy, 'healthy'),
        (HealthStatus.diseased, 'diseased'),
        (HealthStatus.unidentified, 'unidentified'),
      ]) {
        await _pumpAt(tester, HealthStatusBadge(status: status));
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').toLowerCase() == label,
          ),
          findsOneWidget,
          reason: label,
        );
      }
    });
  });

  group('ScanActivityTile', () {
    testWidgets('a long disease name does not overflow a 375px row',
        (tester) async {
      await _pumpAt(
        tester,
        const ScanActivityTile(
          title: 'Tomato Spider mites Two-spotted spider mite infestation',
          plant: 'Tomato',
          subtitle: '2h ago',
          confidence: 92,
          isHealthy: false,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides the confidence figure for an unidentified scan',
        (tester) async {
      await _pumpAt(
        tester,
        const ScanActivityTile(
          title: 'No leaf detected',
          subtitle: 'Just now',
          confidence: 97,
          isHealthy: false,
          isIdentifiable: false,
        ),
      );
      // "97% confidence that there is no leaf" is not information a user wants.
      expect(find.text('97%'), findsNothing);
    });
  });

  group('PhotoBand', () {
    Widget band() => PhotoBand(
          image: AppAssets.fieldFoliage,
          height: 116,
          child: const Text('Good evening'),
        );

    testWidgets('fixed-height band does not overflow on a 320px phone',
        (tester) async {
      await _pumpAt(tester, band(), size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 2x system text', (tester) async {
      await _pumpAt(tester, band(), textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the photograph is decorative and stays out of semantics',
        (tester) async {
      await _pumpAt(tester, band());
      // The overlaid text carries the meaning; the image must not be announced.
      expect(find.text('Good evening'), findsOneWidget);
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images, isNotEmpty);
      expect(
        find.ancestor(
          of: find.byType(Image).first,
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('state views', () {
    testWidgets('EmptyState renders its call to action', (tester) async {
      var tapped = false;
      await _pumpAt(
        tester,
        EmptyState(
          icon: Icons.history_rounded,
          title: 'No scans yet',
          message: 'Scan your first plant to start building your history.',
          actionLabel: 'Scan a plant',
          onAction: () => tapped = true,
        ),
      );
      await tester.tap(find.text('Scan a plant'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ErrorState offers a retry and shows no raw exception',
        (tester) async {
      await _pumpAt(
        tester,
        ErrorState(
          message: 'Unable to connect to PlantDoc.',
          onRetry: () {},
        ),
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('LoadingState renders static skeletons under reduced motion',
        (tester) async {
      tester.view.physicalSize = const Size(375, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: LoadingState(rows: 3)),
          ),
        ),
      );
      // No pumpAndSettle: a looping animation here would never settle.
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
