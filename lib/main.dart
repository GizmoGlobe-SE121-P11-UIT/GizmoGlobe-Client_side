import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_success_webview.dart';
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_screen_webview.dart';
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_screen_view.dart';
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
import 'package:gizmoglobe_client/services/platform_actions_stub.dart'
    if (dart.library.html) 'package:gizmoglobe_client/services/platform_actions_web.dart'
    as platform_actions;

// Function to get hash path from platform actions
String getHashPath() {
  if (kIsWeb) {
    return platform_actions.getHashPath();
  }
  return '';
}

// Function to normalize initial URL for hash strategy
void normalizeInitialUrlForHashStrategy() {
  if (kIsWeb) {
    platform_actions.normalizeInitialUrlForHashStrategy();
  }
}

// Use a single navigator key instance to avoid rebuild-induced pops on web
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

  // Load .env uniformly; it's declared as an asset in pubspec
  await dotenv.load(fileName: ".env");

  // Use hash-based URLs on web so refreshes work without server config
  // However, we need to check for Firebase Auth redirects BEFORE normalizing
  // because Firebase Auth redirects use query parameters that hash routing might interfere with
  if (kIsWeb) {
    // Check if we're returning from a Firebase Auth redirect BEFORE setting hash strategy
    // This allows getRedirectResult() to work properly
    final initialUrl = Uri.base.toString();
    final hasAuthRedirect = initialUrl.contains('__/auth/handler') ||
        initialUrl.contains('apiKey=') ||
        initialUrl.contains('code=') ||
        initialUrl.contains('state=');

    if (!hasAuthRedirect) {
      // Only set hash strategy if we're not handling an auth redirect
      platform_actions.setUrlStrategyWeb();
      normalizeInitialUrlForHashStrategy();
    }
  }
  await _setup();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Ensure persistent auth session on web
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

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
          return BlocProvider(
            create: (context) => MainScreenCubit(),
            child: CartProvider(
              child: MaterialApp(
                navigatorKey: rootNavigatorKey,
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
                        navigatorKey: rootNavigatorKey, child: wrapped);
                  }
                  return wrapped;
                },
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: const ColorScheme(
                    brightness: Brightness.light,
                    primary: Color(0xFF0F4C81),
                    onPrimary: Colors.white,
                    secondary: Color(0xFF638CC7),
                    onSecondary: Colors.white,
                    primaryContainer: Color(0xFF638CC7),
                    secondaryContainer: Color(0xFF0F4C81),
                    surface: Colors.white,
                    onSurface: Colors.black,
                    onSurfaceVariant: Color(0xFF757575),
                    error: Color(0xFFD32F2F),
                    onError: Colors.white,
                    shadow: Color(0x1A000000),
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  canvasColor: Colors.white,
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
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                  ),
                  textTheme: const TextTheme(
                    bodyLarge: TextStyle(color: Colors.black),
                    bodyMedium: TextStyle(color: Colors.black),
                    titleLarge: TextStyle(color: Colors.black),
                    titleMedium: TextStyle(color: Colors.black),
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: const ColorScheme(
                    brightness: Brightness.dark,
                    primary: Color(0xFF0F4C81),
                    onPrimary: Colors.white,
                    secondary: Color(0xFF638CC7),
                    onSecondary: Colors.black,
                    primaryContainer: Color(0xFF0F4C81),
                    secondaryContainer: Color(0xFF638CC7),
                    surface: Color(0xFF121212),
                    onSurface: Colors.white,
                    onSurfaceVariant: Color(0xFFE0E0E0),
                    error: Color(0xFFEF5350),
                    onError: Colors.white,
                    shadow: Color(0x33000000),
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  canvasColor: const Color(0xFF121212),
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
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF121212),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: const Color(0xFF0F4C81),
                    indicatorColor:
                        const Color(0xFF638CC7).withValues(alpha: 0.3),
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
                  '/': (context) => const AuthWrapper(),
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
                  // Note: /checkout-success is handled in onGenerateRoute to support query parameters
                },
                onGenerateRoute: (settings) {
                  String cleanRouteName = settings.name ?? '';

                  // Handle Firebase Auth handler path - this is needed for redirect flow
                  if (kIsWeb && cleanRouteName.contains('__/auth/handler')) {
                    // Let AuthWrapper handle the redirect result
                    return MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                      settings: settings,
                    );
                  }

                  // On web, if framework tries to build '/', prefer current hash route
                  if (kIsWeb &&
                      (cleanRouteName.isEmpty || cleanRouteName == '/')) {
                    final hashPath = getHashPath();
                    if (hashPath.isNotEmpty && hashPath.startsWith('/')) {
                      cleanRouteName = hashPath;
                    }
                  }

                  // Extract base route name (remove query parameters for route matching)
                  // Query parameters may be in the route name or in the hash fragment
                  String baseRouteName = cleanRouteName;
                  if (baseRouteName.contains('?')) {
                    baseRouteName = baseRouteName.split('?').first;
                  }
                  if (baseRouteName == '/products') {
                    return PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductScreen.newInstance(),
                      settings: RouteSettings(name: cleanRouteName),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 150),
                    );
                  }

                  // User sub routes for web navigation
                  if (baseRouteName == '/user/personal-information' ||
                      baseRouteName == '/user/addresses') {
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

                  // Handle checkout route
                  if (baseRouteName == '/checkout') {
                    // New checkout flow - invoice created locally
                    if (kIsWeb) {
                      return PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CheckoutScreenWebView.newInstance(
                          cartItems: [], // Will be initialized from cart
                        ),
                        settings: RouteSettings(name: cleanRouteName),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      );
                    } else {
                      return PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CheckoutScreen.newInstance(
                          cartItems: [], // Will be initialized from cart
                        ),
                        settings: RouteSettings(name: cleanRouteName),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      );
                    }
                  }

                  // Handle checkout route with sales invoice ID (legacy)
                  // Format: /checkout/{sales_invoice_id}
                  if (baseRouteName.startsWith('/checkout/')) {
                    final parts = baseRouteName.split('/');
                    if (parts.length >= 3) {
                      final salesInvoiceID = parts[2];
                      if (kIsWeb) {
                        return PageRouteBuilder(
                          pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                              CheckoutScreenWebView.newInstanceFromInvoiceId(
                            salesInvoiceID: salesInvoiceID,
                          ),
                          settings: RouteSettings(name: cleanRouteName),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        );
                      } else {
                        return PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  CheckoutScreen.newInstanceFromInvoiceId(
                            salesInvoiceID: salesInvoiceID,
                          ),
                          settings: RouteSettings(name: cleanRouteName),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        );
                      }
                    }
                  }

                  // Handle checkout success route (Stripe Checkout redirect)
                  // This route may include query parameters like ?session_id=...
                  if (baseRouteName == '/checkout-success') {
                    return PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const CheckoutSuccessWebView(),
                      settings: RouteSettings(name: cleanRouteName),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    );
                  }

                  // Handle order routes with hash-based navigation
                  if (baseRouteName == '/orders' ||
                      baseRouteName.startsWith('/orders/')) {
                    OrderOption initialTab = OrderOption.toShip;

                    // Parse hash-based URL path to determine initial tab
                    if (baseRouteName.endsWith('/to-ship')) {
                      initialTab = OrderOption.toShip;
                    } else if (baseRouteName.endsWith('/to-receive')) {
                      initialTab = OrderOption.toReceive;
                    } else if (baseRouteName.endsWith('/completed')) {
                      initialTab = OrderOption.completed;
                    } else if (baseRouteName == '/orders') {
                      initialTab = OrderOption.toShip; // Default
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

                  // Handle product category routes
                  if (baseRouteName.startsWith('/products/')) {
                    // The ProductScreenWebView will parse the category from initState
                    return PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductScreen.newInstance(),
                      settings: RouteSettings(name: cleanRouteName),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 150),
                    );
                  }
                  return null;
                },
                // Let the browser URL (hash) decide the initial route
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

    _initializeWeb();
  }

  Future<void> _initializeWeb() async {
    if (kIsWeb) {
      try {
        // Check for redirect result from Google sign-in
        // This handles the redirect flow when user returns from Google authentication
        // getRedirectResult() must be called before any other Firebase Auth operations
        // and it can only be called once per redirect

        // First check if there's already an authenticated user (might be set by redirect)
        // Check if we're on the Firebase Auth handler path or have auth-related query params
        final isAuthHandler = Uri.base.path.contains('__/auth/handler');
        final hasAuthParams = Uri.base.query.contains('apiKey') ||
            Uri.base.query.contains('mode') ||
            Uri.base.query.contains('code') ||
            Uri.base.query.contains('state');

        // Also check hash for auth params (Firebase might put them in hash)
        final hashHasAuthParams = Uri.base.fragment.contains('apiKey') ||
            Uri.base.fragment.contains('mode') ||
            Uri.base.fragment.contains('code') ||
            Uri.base.fragment.contains('state');

        if (isAuthHandler || hasAuthParams || hashHasAuthParams) {
          print(
              'Detected Firebase Auth handler path or auth params - processing redirect...');
          print(
              'isAuthHandler: $isAuthHandler, hasAuthParams: $hasAuthParams, hashHasAuthParams: $hashHasAuthParams');
        }

        // Call getRedirectResult() - this must be called before any other auth operations
        // and it processes the redirect URL parameters automatically
        final redirectResult = await FirebaseAuth.instance.getRedirectResult();
        print('getRedirectResult() completed');

        print(
            'Redirect result - user: ${redirectResult.user != null ? redirectResult.user!.uid : "null"}, '
            'credential: ${redirectResult.credential != null}, '
            'additionalUserInfo: ${redirectResult.additionalUserInfo}');

        // Wait a moment for Firebase to process the redirect result
        // Sometimes Firebase needs a moment to set the user after redirect
        await Future.delayed(const Duration(milliseconds: 500));

        // Check currentUser again after getRedirectResult and delay
        final afterRedirectUser = FirebaseAuth.instance.currentUser;
        print(
            'CurrentUser after getRedirectResult (after delay): ${afterRedirectUser != null ? afterRedirectUser.uid : "null"}');

        // Check for errors in the redirect result
        if (redirectResult.user == null && redirectResult.credential == null) {
          // Check if there's an error in the URL that might indicate why redirect failed
          final currentUrl = Uri.base.toString();
          final hash = Uri.base.fragment;
          // Check if there are any error parameters in the URL
          if (currentUrl.contains('error=') || hash.contains('error=')) {}
        }

        // Use the user from redirectResult if available, otherwise check currentUser
        // Firebase sometimes sets currentUser directly even if redirectResult.user is null
        User? authenticatedUser = redirectResult.user ?? afterRedirectUser;

        if (authenticatedUser != null) {
          // User successfully signed in via redirect
          print('Google sign-in redirect successful: ${authenticatedUser.uid}');
          print('User email: ${authenticatedUser.email}');
          print('User display name: ${authenticatedUser.displayName}');

          // Clear guest data after successful authentication
          await _webGuestService.clearGuestUser();

          // Setup user data in Firestore (similar to popup flow)
          await _setupUserDataFromRedirect(authenticatedUser);
        } else {
          // Check if there was an error in the redirect
          if (redirectResult.credential != null) {
            print('Redirect completed with credential but no user');
          }

          // Listen to authStateChanges for a short time to catch async auth state changes
          // This is important because Firebase might set the user asynchronously after redirect
          print('Waiting for authStateChanges to detect user...');
          bool userDetected = false;
          final subscription =
              FirebaseAuth.instance.authStateChanges().listen((User? user) {
            if (user != null && !userDetected) {
              userDetected = true;
              print('User detected via authStateChanges: ${user.uid}');
              // Handle user setup asynchronously
              _webGuestService.clearGuestUser().then((_) {
                _setupUserDataFromRedirect(user);
              });
            }
          });

          // Wait up to 3 seconds for auth state to change
          await Future.delayed(const Duration(milliseconds: 3000));
          await subscription.cancel();

          final finalUserCheck = FirebaseAuth.instance.currentUser;
          print(
              'Final currentUser check: ${finalUserCheck != null ? finalUserCheck.uid : "null"}');

          if (finalUserCheck != null && !userDetected) {
            print('User authenticated after waiting: ${finalUserCheck.uid}');
            // User is authenticated, clear guest data and setup user data
            await _webGuestService.clearGuestUser();
            await _setupUserDataFromRedirect(finalUserCheck);
          } else if (finalUserCheck == null && !userDetected) {
            // No redirect result and no current user - check if we need to create a guest user
            print(
                'No redirect result and no authenticated user - creating guest user');
            // For web, only create a guest user in local storage if nobody is currently logged in
            // Note: Guest users are NOT created in Firebase Auth, only stored locally
            await _webGuestService.createOrGetGuestUser();
          }
        }
      } catch (e, stackTrace) {
        print('Error initializing web: $e'); // Always print
        print('Stack trace: $stackTrace'); // Always print
        // Even if redirect check fails, try to create guest if no user exists
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            if (kDebugMode) {
              print('Found authenticated user after error: ${currentUser.uid}');
            }
            // User is authenticated, clear guest data and setup user data
            await _webGuestService.clearGuestUser();
            await _setupUserDataFromRedirect(currentUser);
          } else if (currentUser == null) {
            if (kDebugMode) {
              print('No authenticated user after error - creating guest user');
            }
            await _webGuestService.createOrGetGuestUser();
          }
        } catch (guestError) {
          if (kDebugMode) {
            print('Error creating guest user: $guestError');
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupUserDataFromRedirect(User user) async {
    try {
      // Import Firestore here to avoid circular dependencies
      final firestore = FirebaseFirestore.instance;

      // Check if user document already exists
      final userDocRef = firestore.collection('users').doc(user.uid);
      final customerDocRef = firestore.collection('customers').doc(user.uid);

      final userDoc = await userDocRef.get();
      final userExists = userDoc.exists;

      // Prepare user data
      final Map<String, dynamic> userData = {
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'userid': user.uid,
        'role': 'customer',
        'isGuest': false,
      };

      // Prepare customer data
      final Map<String, dynamic> customerData = {
        'customerID': user.uid,
        'customerName': user.displayName ?? '',
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'isGuest': false,
      };

      // Only set createdAt for new users
      if (!userExists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        customerData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Use batch write to ensure both operations succeed or fail together
      // Use merge to preserve existing data if user already exists
      final batch = firestore.batch();
      batch.set(userDocRef, userData, SetOptions(merge: true));
      batch.set(customerDocRef, customerData, SetOptions(merge: true));
      await batch.commit();

      if (kDebugMode) {
        print('User data setup completed for redirect sign-in');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up user data from redirect: $e');
      }
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

        // For web, if user is authenticated via Firebase Auth, go to main screen
        // Note: Guest users are stored locally, not in Firebase Auth
        if (kIsWeb && snapshot.hasData) {
          return const MainScreen();
        }

        // For mobile or if user is authenticated via Firebase Auth, go to main screen
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
