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
import 'package:gizmoglobe_client/providers/language_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          if (kDebugMode) {
            print('Current locale: ${languageProvider.currentLocale}');
            print('Supported locales: ${[Locale('en'), Locale('vi')]}');
          }
          return BlocProvider(
            create: (context) => MainScreenCubit(),
            child: CartProvider(
              child: MaterialApp(
                title: 'GizmoGlobe',
                themeMode: themeProvider.themeMode,
                locale: languageProvider.currentLocale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('vi'),
                ],
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  if (kDebugMode) {
                    print('Locale resolution callback called');
                    print('Requested locale: $locale');
                    print('Supported locales: $supportedLocales');
                  }
                  // Nếu locale không được hỗ trợ, trả về tiếng Việt
                  if (!supportedLocales.contains(locale)) {
                    if (kDebugMode) {
                      print('Locale not supported, returning Vietnamese');
                    }
                    return const Locale('vi');
                  }
                  return locale;
                },
                builder: (context, child) {
                  if (kDebugMode) {
                    print('MaterialApp builder called');
                    print(
                        'Current locale in builder: ${Localizations.localeOf(context)}');
                  }
                  return Localizations.override(
                    context: context,
                    locale: languageProvider.currentLocale,
                    child: child!,
                  );
                },
                theme: ThemeData(
                  colorScheme: ColorScheme(
                    brightness: Brightness.light,
                    primary: const Color(0xFF0F4C81),
                    onPrimary: Colors.white,
                    secondary: const Color(0xFF638CC7),
                    onSecondary: Colors.white,
                    primaryContainer: const Color(0xFF638CC7),
                    secondaryContainer: const Color(0xFF0F4C81),
                    surface: Colors.white,
                    onSurface: Colors.black,
                    onSurfaceVariant: Colors.black87,
                    error: Colors.red[400]!,
                    onError: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Colors.black),
                    bodyMedium: TextStyle(color: Colors.black),
                    titleLarge: TextStyle(color: Colors.black),
                    titleMedium: TextStyle(color: Colors.black),
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: const ColorScheme(
                    brightness: Brightness.dark,
                    // primary: Color(0xFF638CC7),
                    // onPrimary: Colors.black,
                    primary: Color(0xFF0F4C81),
                    onPrimary: Colors.white,
                    secondary: Color(0xFF638CC7),
                    onSecondary: Colors.black,
                    primaryContainer: Color(0xFF0F4C81),
                    secondaryContainer: Color(0xFF638CC7),
                    surface: Color(0xFF121212),
                    onSurface: Colors.white,
                    onSurfaceVariant: Colors.white70,
                    error: Colors.red,
                    onError: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  scaffoldBackgroundColor: Color(0xFF121212),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF121212),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: const Color(0xFF0F4C81),
                    indicatorColor: const Color(0xFF638CC7).withOpacity(0.3),
                    labelTextStyle: WidgetStateProperty.all(
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Colors.white),
                    bodyMedium: TextStyle(color: Colors.white),
                    titleLarge: TextStyle(color: Colors.white),
                    titleMedium: TextStyle(color: Colors.white),
                    labelLarge: TextStyle(color: Color(0xFF638CC7)),
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
          // return const MainScreen();
          return const MainScreen();
        }

        // For all other cases, show sign in screen
        return SignInScreen.newInstance();
      },
    );
  }
}
