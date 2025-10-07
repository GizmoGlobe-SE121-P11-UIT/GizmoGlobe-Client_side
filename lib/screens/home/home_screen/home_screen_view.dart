import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/product/favorites/favorites_cubit.dart';
import 'package:gizmoglobe_client/widgets/product/product_card.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/components/home/web_hero_section.dart';
import 'package:gizmoglobe_client/components/home/web_category_nav.dart';
import 'package:gizmoglobe_client/components/home/web_best_sellers_section.dart';
import 'package:gizmoglobe_client/components/home/web_favorites_section.dart';
import 'package:gizmoglobe_client/components/home/web_features_section.dart';
import 'package:gizmoglobe_client/components/general/web_footer.dart';
import 'package:flutter/foundation.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => HomeScreenCubit(
          favoritesCubit: context.read<FavoritesCubit>(),
        ),
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
    cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on web platform
    if (kIsWeb) {
      return BlocProvider(
        create: (context) => HomeScreenCubit(
          favoritesCubit: context.read<FavoritesCubit>(),
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocBuilder<HomeScreenCubit, HomeScreenState>(
            builder: (context, state) {
              // Initialize the cubit when the widget is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<HomeScreenCubit>().initialize();
              });

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const WebHeader(),
                    const WebHeroSection(),
                    const SizedBox(height: 80),
                    const WebCategoryNav(),
                    const SizedBox(height: 80),
                    WebBestSellersSection(products: state.bestSellerProducts),
                    const SizedBox(height: 80),
                    WebFavoritesSection(products: state.favoriteProducts),
                    const SizedBox(height: 80),
                    const WebFeaturesSection(),
                    const SizedBox(height: 80),
                    const WebFooter(),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Mobile/Desktop version
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
                title: Stack(children: [
                  Center(
                    child: Semantics(
                      label: S.of(context).appLogo,
                      child: const AppLogo(height: 50),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: SizedBox()),
                      Semantics(
                        label: S.of(context).chatButton,
                        child: IconButton(
                          icon: Icon(
                            Icons.chat,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/chat');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ]),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    BlocBuilder<HomeScreenCubit, HomeScreenState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            _buildCarousel(
                              context,
                              title: S.of(context).bestSellers,
                              products: state.bestSellerProducts,
                              onSeeAll: () {
                                Navigator.pushNamed(context, '/products');
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCarousel(
                              context,
                              title: S.of(context).favorites,
                              products: state.favoriteProducts,
                              onSeeAll: () {
                                Navigator.pushNamed(context, '/products');
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

  Widget _buildCarousel(BuildContext context,
      {required String title,
      required List<Product> products,
      required VoidCallback onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              child: Text(S.of(context).seeAll),
            ),
          ],
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length > 5 ? 5 : products.length,
            itemBuilder: (context, index) {
              return SizedBox(
                  width: 150, child: ProductCard(product: products[index]));
            },
          ),
        ),
      ],
    );
  }
}
