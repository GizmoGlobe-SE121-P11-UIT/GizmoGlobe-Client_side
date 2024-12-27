import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/cart/cart_screen/cart_screen_cubit.dart';
import '../widgets/product/favorites/favorites_cubit.dart';

class CartProvider extends StatelessWidget {
  final Widget child;

  const CartProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CartScreenCubit(),
        ),
        BlocProvider(
          create: (context) => FavoritesCubit(),
        ),
      ],
      child: child,
    );
  }
} 