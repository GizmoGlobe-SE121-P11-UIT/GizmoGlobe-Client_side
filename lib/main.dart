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
import 'package:gizmoglobe_client/screens/chat/chat_screen/chat_screen_view.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_view.dart';
import 'package:gizmoglobe_client/screens/cart/cart_screen/cart_screen_view.dart';
import 'package:gizmoglobe_client/screens/user/user_screen/user_screen_view.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_view.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_view.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
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
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/chat/floating_chat.dart';

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child; // No animation
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await _setup();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // final database = Database();
    // Initialize Firebase App Check only on mobile platforms (not web)
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.deviceCheck,
      );

      // Configure retry behavior for App Check
      FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    }

    await Database().initialize();

    // Only request permissions on mobile platforms (not web)
    if (!kIsWeb) {
      await Permission.camera.request();
      await Permission.photos.request();
    }
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

  // Only initialize Stripe on mobile platforms (not web)
  if (!kIsWeb) {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  }
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
          final GlobalKey<NavigatorState> _rootNavigatorKey =
              GlobalKey<NavigatorState>();
          return BlocProvider(
            create: (context) => MainScreenCubit(),
            child: CartProvider(
              child: MaterialApp(
                navigatorKey: _rootNavigatorKey,
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

                  Widget wrapped = Localizations.override(
                    context: context,
                    locale: languageProvider.currentLocale,
                    child: child!,
                  );
                  // Inject floating chat only on web
                  if (kIsWeb) {
                    return FloatingChat(
                        child: wrapped, navigatorKey: _rootNavigatorKey);
                  }
                  return wrapped;
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
                  pageTransitionsTheme: kIsWeb
                      ? const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android: NoTransitionsBuilder(),
                            TargetPlatform.iOS: NoTransitionsBuilder(),
                            TargetPlatform.linux: NoTransitionsBuilder(),
                            TargetPlatform.macOS: NoTransitionsBuilder(),
                            TargetPlatform.windows: NoTransitionsBuilder(),
                            TargetPlatform.fuchsia: NoTransitionsBuilder(),
                          },
                        )
                      : const PageTransitionsTheme(),
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
                  pageTransitionsTheme: kIsWeb
                      ? const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android: NoTransitionsBuilder(),
                            TargetPlatform.iOS: NoTransitionsBuilder(),
                            TargetPlatform.linux: NoTransitionsBuilder(),
                            TargetPlatform.macOS: NoTransitionsBuilder(),
                            TargetPlatform.windows: NoTransitionsBuilder(),
                            TargetPlatform.fuchsia: NoTransitionsBuilder(),
                          },
                        )
                      : const PageTransitionsTheme(),
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
                  '/home': (context) => const MainScreen(),
                  '/sign-in': (context) => SignInScreen.newInstance(),
                  '/sign-up': (context) => SignUpScreen.newInstance(),
                  '/forget-password': (context) =>
                      ForgetPasswordScreen.newInstance(),
                  '/main': (context) => const MainScreen(),
                  '/chat': (context) => ChatScreen.newInstance(),
                  '/products': (context) => ProductScreen.newInstance(),
                  '/cart': (context) => CartScreen.newInstance(),
                  '/user': (context) => UserScreen.newInstance(),
                  '/user-settings': (context) => UserScreen.newInstance(),
                  '/vouchers': (context) => VoucherScreen.newInstance(),
                },
                onGenerateRoute: (settings) {
                  // Clean the route name to remove any hash fragments
                  String cleanRouteName = settings.name ?? '';
                  if (cleanRouteName.contains('#')) {
                    cleanRouteName = cleanRouteName.split('#')[0];
                  }

                  // User sub routes for web navigation
                  if (cleanRouteName == '/user/personal-information' ||
                      cleanRouteName == '/user/addresses') {
                    return PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UserScreen.newInstance(),
                      settings: RouteSettings(name: cleanRouteName),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 150),
                    );
                  }

                  if (cleanRouteName == '/orders' ||
                      cleanRouteName.startsWith('/orders?')) {
                    // Parse query parameters to determine initial tab
                    final uri = Uri.parse(cleanRouteName);
                    final tabParam = uri.queryParameters['tab'];
                    OrderOption initialTab = OrderOption.toShip;

                    switch (tabParam) {
                      case 'to-ship':
                        initialTab = OrderOption.toShip;
                        break;
                      case 'to-receive':
                        initialTab = OrderOption.toReceive;
                        break;
                      case 'completed':
                        initialTab = OrderOption.completed;
                        break;
                      default:
                        initialTab = OrderOption.toShip;
                    }

                    return PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          OrderScreen.newInstance(orderOption: initialTab),
                      settings: RouteSettings(name: cleanRouteName),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    );
                  }
                  return null;
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final WebGuestService _webGuestService = WebGuestService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeWebGuest();
  }

  Future<void> _initializeWebGuest() async {
    if (kIsWeb) {
      try {
        // For web, only create a guest user if nobody is currently logged in
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          await _webGuestService.createOrGetGuestUser();
        } else {
          if (kDebugMode) {
            print(
                'Skipping guest creation: user already logged in (${currentUser.uid})');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing web guest: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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

        // For web, if user is authenticated (including guest), go to main screen
        if (kIsWeb && snapshot.hasData) {
          return const MainScreen();
        }

        // For mobile or if user is authenticated, go to main screen
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // For mobile, show sign in screen
        if (!kIsWeb) {
          return SignInScreen.newInstance();
        }

        // For web, go to main screen (guest user should be created automatically)
        return const MainScreen();
      },
    );
  }
}
