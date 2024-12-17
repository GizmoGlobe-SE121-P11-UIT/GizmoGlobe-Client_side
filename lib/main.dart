import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/authentication/forget_password_screen/forget_password_view.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_view.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_up_screen/sign_up_view.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_view.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_view.dart';
import 'package:gizmoglobe_client/screens/main/drawer/drawer_cubit.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/firebase_options.dart';
import 'package:gizmoglobe_client/widgets/filter/advanced_filter_search/advanced_filter_search_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );
    Database().initialize();
    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing Firebase: $e'),
          ),
        ),
      ));
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => MainScreenCubit()),
        BlocProvider(create: (context) => DrawerCubit()),
      ],
      child: MaterialApp(
        title: 'GizmoGlobe',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: const ColorScheme(
            primary: Color(0xFF6CC4F4),
            onPrimary: Color(0xFF4A94F1),
            secondary: Color(0xFF6465F1),
            onSecondary: Color(0xFF292B5C),
            primaryContainer: Color(0xFF323F73),
            secondaryContainer: Color(0xFF608BC1),
            surface: Color(0xFF202046),
            onSurface: Color(0xFFF3F3E0),
            onSurfaceVariant: Color(0xFF202046),
            error: Colors.red,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
        ),
        routes: {
          '/sign-in': (context) => SignInScreen.newInstance(),
          '/sign-up': (context) => SignUpScreen.newInstance(),
          '/forget-password': (context) => ForgetPasswordScreen.newInstance(),
          '/main': (context) => const MainScreen(),
          '/home': (context) => HomeScreen.newInstance(),
        },
        home: const AuthWrapper(),
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
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return SignInScreen.newInstance();
      },
    );
  }
}