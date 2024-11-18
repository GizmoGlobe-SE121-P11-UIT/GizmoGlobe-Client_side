import 'package:flutter/material.dart';

import '../../home/home_screen/home_screen_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final List<Widget Function()> widgetList = [
        () => const HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30)
          ),
          child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              onTap: (value) {
                if (value != index) {
                  setState(() {
                    index = value;
                  });
                }
              },
              currentIndex: index,
              backgroundColor: Colors.white,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 3,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: "Home"
                ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.currency_exchange),
                    label: "Transaction"
                ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: "Stats"
                ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile"
                ),
              ]
          ),
        ),
        body: widgetList[index]()
    );
  }
}