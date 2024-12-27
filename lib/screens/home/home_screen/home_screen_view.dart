import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_button.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/widgets/product/product_card.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_state.dart';

import '../../../data/database/database.dart';
import '../../../data/firebase/firebase.dart';
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
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<HomeScreenCubit, HomeScreenState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            _buildCarousel(
                              context,
                              title: 'Best Sellers',
                              products: state.bestSellerProducts,
                              onSeeAll: () {
                                // Navigate to best sellers list
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCarousel(
                              context,
                              title: 'Favorites',
                              products: state.favoriteProducts,
                              onSeeAll: () {
                                // Navigate to favorites list
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, {required String title, required List<Product> products, required VoidCallback onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length > 5 ? 5 : products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}