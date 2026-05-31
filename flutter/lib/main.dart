import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/navigation/app_page_route.dart';
import 'core/theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/plant_tracker_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', // Replace with your Supabase URL
    anonKey: 'your-anon-key-here', // Replace with your anon key
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A1410),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PlantDocApp());
}

class PlantDocApp extends StatelessWidget {
  const PlantDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantDoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/welcome',
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/welcome' => const WelcomeScreen(),
          '/home' => const HomeScreen(),
          '/scan' => const ScanScreen(),
          '/result' => const ScanResultScreen(),
          '/tracker' => PlantTrackerScreen(
            initialCropIndex: settings.arguments is int
                ? settings.arguments as int
                : 0,
          ),
          '/history' => const HistoryScreen(),
          '/profile' => const ProfileScreen(),
          _ => null,
        };

        if (page == null) return null;

        final duration = settings.name == '/welcome'
            ? AppPageRoute.welcomeDuration
            : AppPageRoute.defaultDuration;

        return AppPageRoute.fade(page, settings: settings, duration: duration);
      },
    );
  }
}
