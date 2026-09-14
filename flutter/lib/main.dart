import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/navigation/app_page_route.dart';
import 'core/navigation/main_shell.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/plant_tracker/providers/plant_batch_provider.dart';
import 'features/plant_tracker/services/plant_reminder_service.dart';
import 'screens/registration_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl.trim(),
    anonKey: supabaseAnonKey.trim(),
  );

  ApiService.configure(apiBaseUrlFromEnv: dotenv.env['API_BASE_URL']);

  await PlantReminderService.instance.initialize();
  await PlantReminderService.instance.rescheduleAll();

  // Light botanical ground, so system chrome needs dark icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
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

class PlantDocApp extends StatelessWidget {
  const PlantDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return MaterialApp(
      title: 'PlantDoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: authProvider.isAuthenticated ? '/home' : '/welcome',
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/welcome' => const WelcomeScreen(),
          '/register' => const RegisterScreen(),
          // The four primary tabs live inside one shell, so they share a route.
          '/home' => const MainShell(),
          '/history' => const MainShell(initialIndex: 1),
          '/tracker' => const MainShell(initialIndex: 2),
          '/profile' => const MainShell(initialIndex: 3),
          '/scan' => const ScanScreen(),
          '/result' => const ScanResultScreen(),
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
