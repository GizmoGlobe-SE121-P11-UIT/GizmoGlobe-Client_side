// lib/screens/main/main_screen/main_screen_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/main/main_screen/main_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_view.dart';
import '../../../widgets/general/selectable_gradient_icon.dart';
import '../../cart/cart_screen/cart_screen_view.dart';
import '../../home/home_screen/home_screen_view.dart';
import '../../user/user_screen/user_screen_view.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final List<Widget Function()> widgetList = [
        () => HomeScreen.newInstance(),
        () => ProductScreen.newInstance(),
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widgetList[index](),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          onTap: (value) {
            if (value == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen.newInstance()),
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
              label: "Home", // "Trang chủ"
            ),
            BottomNavigationBarItem(
              icon: SelectableGradientIcon(
                icon: Icons.shopping_bag,
                isSelected: index == 1,
              ),
              label: "Product", // "Sản phẩm"
            ),
            const BottomNavigationBarItem(
              icon: SelectableGradientIcon(
                icon: Icons.shopping_cart,
                isSelected: false,
              ),
              label: "Cart", // "Giỏ hàng"
            ),
            BottomNavigationBarItem(
              icon: SelectableGradientIcon(
                icon: Icons.person,
                isSelected: index == 2,
              ),
              label: "User", // "Người dùng"
            ),
          ],
        ),
      ),
    );
  }
}