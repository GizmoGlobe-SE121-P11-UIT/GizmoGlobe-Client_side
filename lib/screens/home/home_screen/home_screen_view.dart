import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_button.dart';

import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/general/field_with_icon.dart';
import '../../main/drawer/drawer_cubit.dart';
import '../product_list_search/product_list_search_view.dart';
import 'home_screen_cubit.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  },
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                title: const Center(
                    child: AppLogo(height: 60,)
                ),
                actions: const [
                  SizedBox(width: 48),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FieldWithIcon(
                            controller: searchController,
                            hintText: 'What do you need?',
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        const SizedBox(width: 4),

                        GradientIconButton(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          iconSize: 28,
                          onPressed: () {
                            cubit.changeSearchText(searchController.text);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductListSearchScreen.newInstance(
                                  initialSearchText: searchController.text,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    )
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