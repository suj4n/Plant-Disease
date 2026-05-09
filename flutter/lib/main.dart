import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/guide_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plant_tracker_screen.dart';
import 'screens/result_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/splash_screen.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings init =
      InitializationSettings(android: androidInit, iOS: iosInit);

  await notificationsPlugin.initialize(settings: init);

  final AndroidFlutterLocalNotificationsPlugin? android = notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.requestNotificationsPermission();

  final IOSFlutterLocalNotificationsPlugin? ios = notificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>(
        );
  await ios?.requestPermissions(alert: true, badge: true, sound: true);

  runApp(const PlantDiseaseApp());
}

class PlantDiseaseApp extends StatelessWidget {
  const PlantDiseaseApp({super.key});

  static const Color primaryDarkGreen = Color(0xFF1B4332);
  static const Color secondaryMediumGreen = Color(0xFF2D6A4F);
  static const Color accentOrange = Color(0xFFF4A261);
  static const Color backgroundCream = Color(0xFFF5F0E8);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme();
    const ColorScheme colorScheme = ColorScheme.light(
      primary: primaryDarkGreen,
      secondary: secondaryMediumGreen,
      tertiary: accentOrange,
      surface: cardWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryDarkGreen,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Disease App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundCream,
        cardColor: cardWhite,
        textTheme: poppinsTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryDarkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: poppinsTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryMediumGreen,
            foregroundColor: Colors.white,
            textStyle: poppinsTextTheme.labelLarge,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ScanScreen.routeName: (context) => const ScanScreen(),
        ResultScreen.routeName: (context) => const ResultScreen(),
        HistoryScreen.routeName: (context) => const HistoryScreen(),
        PlantTrackerScreen.routeName: (context) => const PlantTrackerScreen(),
        GuideScreen.routeName: (context) => const GuideScreen(),
      },
    );
  }
}
