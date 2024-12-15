// lib/screens/main/main_screen/main_screen_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_cubit.dart';
import '../../../widgets/general/selectable_gradient_icon.dart';
import '../../cart/cart_screen/cart_screen_view.dart';
import '../../home/home_screen/home_screen_view.dart';
import '../../user/user_screen/user_screen_view.dart';
import '../drawer/drawer_cubit.dart';
import '../drawer/drawer_state.dart';
import '../drawer/drawer_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final List<Widget Function()> widgetList = [
        () => HomeScreen.newInstance(),
        () => Container(),
        () => UserScreen.newInstance(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<MainScreenCubit>().getUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: widgetList[index](),
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              onTap: (value) {
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                } else if (value != index) {
                  setState(() {
                    index = value;
                  });
                }
              },
              currentIndex: index,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 3,
              items: [
                BottomNavigationBarItem(
                  icon: SelectableGradientIcon(
                    icon: Icons.home,
                    isSelected: index == 0,
                  ),
                  label: "Home",
                ),
                const BottomNavigationBarItem(
                  icon: SelectableGradientIcon(
                    icon: Icons.shopping_cart,
                    isSelected: false,
                  ),
                  label: "Cart",
                ),
                BottomNavigationBarItem(
                  icon: SelectableGradientIcon(
                    icon: Icons.person,
                    isSelected: index == 2,
                  ),
                  label: "User",
                ),
              ],
            ),
          ),
        ),
        BlocBuilder<DrawerCubit, DrawerState>(
          builder: (context, state) {
            if (state.isOpen) {
              return GestureDetector(
                onTap: () => context.read<DrawerCubit>().closeDrawer(),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const DrawerView(),
      ],
    );
  }
}