import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/widgets/app_logo.dart';
import '../../../../functions/custom_dialog.dart';
import 'package:intl/intl.dart';

import '../../../widgets/gradient_icon_button.dart';
import '../../../widgets/field_with_icon.dart';
import '../../../widgets/invisible_gradient_button.dart';
import '../../main/drawer/drawer_cubit.dart';
import 'home_screen_cubit.dart';
import 'home_screen_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Widget newInstance() =>
      BlocProvider(
        create: (context) => HomeScreenCubit(),
        child: const HomeScreen(),
      );

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  HomeScreenCubit get cubit => context.read<HomeScreenCubit>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController searchController = TextEditingController();

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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: GradientIconButton(
                  icon: Icons.menu_outlined,
                  onPressed: () {
                    context.read<DrawerCubit>().toggleDrawer();
                    context.read<DrawerCubit>().fetchCategories();
                  },
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                title: const Center(
                    child: AppLogo(height: 60,)
                ),
                actions: const [
                  SizedBox(width: 48), // To balance the leading icon
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    FieldWithIcon(
                      controller: searchController,
                      prefixIcon: Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      hintText: 'What do you need?',
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    // Add other widgets here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}