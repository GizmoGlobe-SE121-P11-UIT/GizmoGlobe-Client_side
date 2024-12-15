import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/general/gradient_text.dart';

import '../../../widgets/general/gradient_icon_button.dart';
import 'cart_screen_cubit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  static Widget newInstance() => BlocProvider(
    create: (context) => CartScreenCubit(),
    child: const CartScreen(),
  );

  @override
  State<CartScreen> createState() => _CartScreen();
}

class _CartScreen extends State<CartScreen> {
  CartScreenCubit get cubit => context.read<CartScreenCubit>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () {
              Navigator.pop(context);
            },
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: GradientText(text: 'Cart'),
            ),
        ),
        body: Center(
          child: Column(
            children: [
              Text(
                '[Cart Screen Content]',
                style: TextStyle(
                  fontSize: 20.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}