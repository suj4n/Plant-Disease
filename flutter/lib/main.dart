import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/navigation/app_page_route.dart';
import 'core/constants/app_stats.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/plant_tracker/providers/plant_batch_provider.dart';
import 'features/plant_tracker/services/plant_reminder_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/plant_tracker_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl.trim(),
    anonKey: supabaseAnonKey.trim(),
  );

  ApiService.configure(
    apiBaseUrlFromEnv: dotenv.env['API_BASE_URL'],
  );

  await PlantReminderService.instance.initialize();
  await PlantReminderService.instance.rescheduleAll();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlantBatchProvider()),
      ],
      child: const PlantDocApp(),
    ),
  );
}

String? _trackerSuggestedPlantType(Object? arguments) {
  if (arguments is String) return arguments;
  if (arguments is int) {
    final crops = AppStats.supportedCrops;
    if (arguments >= 0 && arguments < crops.length) {
      return crops[arguments];
    }
  }
  return null;
}

class PlantDocApp extends StatelessWidget {
  const PlantDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return MaterialApp(
      title: 'PlantDoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: authProvider.isAuthenticated ? '/home' : '/welcome',
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/welcome' => const WelcomeScreen(),
          '/register' => const RegisterScreen(),
          '/home' => const HomeScreen(),
          '/scan' => const ScanScreen(),
          '/result' => const ScanResultScreen(),
          '/tracker' => PlantTrackerScreen(
              suggestedPlantType: _trackerSuggestedPlantType(settings.arguments),
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

