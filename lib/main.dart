import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_view.dart';
import 'data/database/database.dart';
import 'firebase_options.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/signup_screen.dart';
import 'screens/main/main_screen/main_screen_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.android,
    );
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
    return MaterialApp(
      title: 'GizmoGlobe',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: const ColorScheme.light(
            surface: Color(0xFFF6F6F6),
            onSurface: Colors.black,
            primary: Color(0xFF0A98FF),
            secondary: Color(0xFFC15BFF),
            tertiary: Color(0xFFFBFF2B),
          )
      ),
      // Define named routes for navigation
      routes: {
        '/login': (context) => LoginScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/main': (context) => const MainScreen(), // Add the MainScreen route
        '/home': (context) => const HomeScreen(),
        // Add more routes for other screens
      },
      home: const AuthWrapper(), // Use AuthWrapper as the home screen
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
          return const MainScreen(); // User is logged in, go to MainScreen
        }
        return LoginScreen(); // User is not logged in, go to LoginScreen
      },
    );
  }
}