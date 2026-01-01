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
import 'package:gizmoglobe_client/components/general/web_footer.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../product/product_screen/product_screen_view.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<HomeScreenCubit, HomeScreenState>(
          builder: (context, state) {
            // Use StreamBuilder to react to auth changes - show sections only for authenticated users
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                final isAuthenticated = authSnapshot.data != null;
                final screenWidth = MediaQuery.of(context).size.width;
                final sectionSpacing = screenWidth >= 600 ? 80.0 : 40.0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const WebHeader(),
                      const WebHeroSection(),
                      WebBestSellersSection(products: state.bestSellerProducts),
                      if (isAuthenticated &&
                          state.favoriteProducts.isNotEmpty) ...[
                        SizedBox(height: sectionSpacing),
                        WebFavoritesSection(products: state.favoriteProducts),
                      ],
                      if (isAuthenticated &&
                          state.recommendedProducts.isNotEmpty) ...[
                        SizedBox(height: sectionSpacing),
                        _buildWebRecommendationSection(
                          context,
                          state.recommendedProducts,
                        ),
                      ],
                      SizedBox(height: sectionSpacing),
                      const WebFooter(),
                    ],
                  ),
                );
              },
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
                automaticallyImplyLeading: false,
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
                              title: S.of(context).bestSellers,
                              products: state.bestSellerProducts,
                              onSeeAll: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ProductScreen.newInstance(
                                                initialProducts:
                                                    state.favoriteProducts)));
                              },
                              length: 4,
                            ),
                            if (!_isGuestMobile())
                              _buildCarousel(
                                context,
                                title: S.of(context).favorites,
                                products: state.favoriteProducts,
                                onSeeAll: () {
                                  Navigator.pushNamed(context, '/products');
                                },
                                length: 4,
                              ),
                            _buildCarousel(
                              context,
                              title: S.of(context).recommendedForYou,
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

    if (products.isEmpty) return Container();

    final itemCount = products.length > length ? length : products.length;

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
            Row(
              children: [
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    textStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
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
              ],
            ),
          ],
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
      ],
    );
  }

  bool _isGuestMobile() {
    // Treat empty userID as guest for non-web
    return Database().userID.isEmpty;
  }

  Widget _buildWebRecommendationSection(
      BuildContext context, List<Product> products) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth >= 900
            ? 80
            : screenWidth >= 600
                ? 40
                : 20,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: show more cards on wider screens
          final maxCards = constraints.maxWidth >= 1400
              ? 7
              : constraints.maxWidth >= 1200
                  ? 6
                  : constraints.maxWidth >= 900
                      ? 5
                      : constraints.maxWidth >= 600
                          ? 3
                          : 2; // Added mobile breakpoint
          final displayCount =
              products.length > maxCards ? maxCards : products.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).recommendedForYou,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isMobile ? -0.5 : -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.of(context).productRecommendationsForYourBuild,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/products');
                    },
                    child: Row(
                      children: [
                        Text(
                          S.of(context).seeAll,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(
                        right: index < displayCount - 1 ? 20 : 0,
                      ),
                      child: WebProductCard(product: products[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
