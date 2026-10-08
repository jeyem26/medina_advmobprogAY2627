import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Firebase configuration
import 'firebase_options.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';

// providers
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // The API host has a safe fallback for platforms that cannot load assets.
  }

  runApp(const RoblesAdvMobProg());
}

class RoblesAdvMobProg extends StatelessWidget {
  const RoblesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // Flutter's built-in themes
            theme: ThemeData.light(useMaterial3: true),

            darkTheme: ThemeData.dark(useMaterial3: true),

            // Controlled by ThemeProvider
            themeMode: themeModel.isDark
                ? ThemeMode.dark
                : ThemeMode.light,

            title: 'E-Commerce App',

            initialRoute: '/splash',

            routes: {
              '/splash': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/signup': (context) => const SignupScreen(),
            },
          );
        },
      ),
    );
  }
}