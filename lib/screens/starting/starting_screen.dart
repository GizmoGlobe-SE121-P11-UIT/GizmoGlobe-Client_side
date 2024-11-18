import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFBFF2B), // Yellow color
              Color(0xFFC15BFF), // Purple color
              Color(0xFF0A98FF), // Blue color
            ],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 80,
                backgroundColor: Color(0xFFC15BFF), // Purple color for avatar background
                child: Text(
                  'App Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'GizmoGlobe', // Change the text here
                style: TextStyle(
                  fontSize: 30, // Increase the font size here
                  color: Colors.white, // You can change the color if needed
                ),
              ),
              const SizedBox(height: 40),
              // Add spacing between text and buttons
              ElevatedButton(
                onPressed: () {
                  // Handle "Tạo tài khoản mới" button press
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                      const Color(0xFFC15BFF)), // Purple color for button
                ),
                child: const Text('Tạo tài khoản mới'),
              ),
              const SizedBox(height: 10), // Add spacing between buttons
              ElevatedButton(
                onPressed: () {
                  // Handle "Đã có tài khoản" button press
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                      const Color(0xFF0A98FF)), // Blue color for button
                ),
                child: const Text('Đã có tài khoản'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
