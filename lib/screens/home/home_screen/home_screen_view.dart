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
      return Scaffold(
        backgroundColor: Theme
            .of(context)
            .scaffoldBackgroundColor,
        body: BlocBuilder<HomeScreenCubit, HomeScreenState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const WebHeader(),
                  const WebHeroSection(),
                  // const SizedBox(height: 80),
                  // const WebCategoryNav(),
                  // const SizedBox(height: 80),
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
      );
    }

    // Mobile/Desktop version
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      label: S
                          .of(context)
                          .appLogo,
                      child: const AppLogo(height: 50),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: SizedBox()),
                      Semantics(
                        label: S
                            .of(context)
                            .chatButton,
                        child: IconButton(
                          icon: Icon(
                            Icons.chat,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
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
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    BlocBuilder<HomeScreenCubit, HomeScreenState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            _buildCarousel(
                              context,
                              title: S
                                  .of(context)
                                  .bestSellers,
                              products: state.bestSellerProducts,
                              onSeeAll: () {
                                Navigator.pushNamed(context, '/products');
                              },
                              length: 4,
                            ),
                            _buildCarousel(
                              context,
                              title: S
                                  .of(context)
                                  .favorites,
                              products: state.favoriteProducts,
                              onSeeAll: () {
                                Navigator.pushNamed(context, '/products');
                              },
                              length: 4,
                            ),
                            _buildCarousel(
                              context,
                              title: "Recommended for You",
                              products: state.recommendedProducts,
                              onSeeAll: () {
                                Navigator.pushNamed(context, '/products');
                              },
                              length: 20,
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

  // dart
  Widget _buildCarousel(BuildContext context,
      {required String title,
        required List<Product> products,
        required VoidCallback onSeeAll,
        required int length}) {
    if (products.isEmpty) return Container();

    final itemCount = products.length > length ? length : products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 24,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        ),
        Row(
          children: [
            Expanded(child: SizedBox()),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(S.of(context).seeAll),
            ),
            Icon(
              Icons.arrow_right_alt_outlined,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ]
        ),
      ],
    );
  }
}