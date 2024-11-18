import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../functions/custom_dialog.dart';
import 'package:intl/intl.dart';

import 'home_screen_cubit.dart';
import 'home_screen_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Widget newInstance() =>
      BlocProvider(
        create: (context) => HomeScreenCubit(),
        child: const HomeScreen(),
      );

  static Widget newInstanceWithTransaction() =>
      BlocProvider(
        create: (context) => HomeScreenCubit(),
        child: const HomeScreen(),
      );

  @override
  State<HomeScreen> createState() => _ModifyTransactionScreen();
}

class _ModifyTransactionScreen extends State<HomeScreen> {
  HomeScreenCubit get cubit => context.read<HomeScreenCubit>();

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
    );
  }
}