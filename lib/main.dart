import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gizmoglobe_client/screens/authentication/forget_password_screen/forget_password_view.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_view.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_up_screen/sign_up_view.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_view.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/firebase_options.dart';
import 'package:gizmoglobe_client/providers/cart_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:gizmoglobe_client/providers/theme_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'consts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _setup();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check with debug token and retry configuration
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );

    // Configure retry behavior for App Check
    FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

    await Database().initialize();
    await Permission.camera.request();
    await Permission.photos.request();
    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
                'Error initializing Firebase: $e'), // 'Lỗi khởi tạo Firebase: $e'
          ),
        ),
      ));
    }
  }
}

Future<void> _setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = stripePublishableKey;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => MainScreenCubit()),
            ],
            child: CartProvider(
              child: MaterialApp(
                title: 'GizmoGlobe',
                themeMode: themeProvider.themeMode,
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  colorScheme: ColorScheme(
                    brightness: Brightness.light,
                    primary: const Color(0xFF2196F3),
                    onPrimary: Colors.white,
                    secondary: const Color(0xFF6465F1),
                    onSecondary: const Color(0xFF292B5C),
                    primaryContainer: const Color(0xFF64B5F6),
                    secondaryContainer: const Color(0xFF64B5F6),
                    surface: Colors.white,
                    onSurface: const Color(0xFF2C3E50),
                    onSurfaceVariant: const Color(0xFF455A64),
                    background: Colors.white,
                    onBackground: const Color(0xFF2C3E50),
                    error: Colors.red[400]!,
                    onError: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF2C3E50),
                    elevation: 0,
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Color(0xFF2C3E50)),
                    bodyMedium: TextStyle(color: Color(0xFF2C3E50)),
                    titleLarge: TextStyle(color: Color(0xFF2C3E50)),
                    titleMedium: TextStyle(color: Color(0xFF2C3E50)),
                  ),
                ),
                darkTheme: ThemeData(
                  primarySwatch: Colors.blue,
                  colorScheme: const ColorScheme(
                    brightness: Brightness.dark,
                    primary: Color(0xFF2196F3),
                    onPrimary: Colors.white,
                    secondary: Color(0xFF6465F1),
                    onSecondary: Color(0xFF292B5C),
                    primaryContainer: Color(0xFF323F73),
                    secondaryContainer: Color(0xFF608BC1),
                    surface: Color(0xFF202046),
                    onSurface: Colors.white,
                    onSurfaceVariant: Colors.white70,
                    background: Color(0xFF202046),
                    onBackground: Colors.white,
                    error: Colors.red,
                    onError: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  scaffoldBackgroundColor: const Color(0xFF202046),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF202046),
                    foregroundColor: Color(0xFFF3F3E0),
                    elevation: 0,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: const Color(0xFF323F73),
                    indicatorColor: const Color(0xFF2196F3).withOpacity(0.3),
                    labelTextStyle: MaterialStateProperty.all(
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Color(0xFFF3F3E0)),
                    bodyMedium: TextStyle(color: Color(0xFFF3F3E0)),
                    titleLarge: TextStyle(color: Color(0xFFF3F3E0)),
                    titleMedium: TextStyle(color: Color(0xFFF3F3E0)),
                  ),
                ),
                routes: {
                  '/sign-in': (context) => SignInScreen.newInstance(),
                  '/sign-up': (context) => SignUpScreen.newInstance(),
                  '/forget-password': (context) =>
                      ForgetPasswordScreen.newInstance(),
                  '/main': (context) => const MainScreen(),
                },
                home: const AuthWrapper(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get the current route name
        final currentRoute = ModalRoute.of(context)?.settings.name;

        // If we're on the sign-up screen, don't redirect
        if (currentRoute == '/sign-up') {
          return SignUpScreen.newInstance();
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        // For all other cases, show sign in screen
        return SignInScreen.newInstance();
      },
    );
  }
}
