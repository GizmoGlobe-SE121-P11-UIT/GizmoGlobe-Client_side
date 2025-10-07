import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/chat/chat_screen/chat_screen_view.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/home/home_screen/home_screen_state.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_view.dart';
import 'package:gizmoglobe_client/widgets/product/favorites/favorites_cubit.dart';

import '../../../enums/processing/sort_enum.dart';

// Main Home Screen Widget
class HomeScreenWeb extends StatelessWidget {
  const HomeScreenWeb({Key? key}) : super(key: key);

  static Widget newInstance() => BlocProvider(
        create: (context) => HomeScreenCubit(
          favoritesCubit: context.read<FavoritesCubit>(),
        ),
        child: const HomeScreenWeb(),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeScreenCubit(
        favoritesCubit: context.read<FavoritesCubit>(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
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
                  const HeroSection(),
                  const SizedBox(height: 80),
                  const CategoryNav(),
                  const SizedBox(height: 80),
                  BestSellersSection(products: state.bestSellerProducts),
                  const SizedBox(height: 80),
                  FavoritesSection(products: state.favoriteProducts),
                  const SizedBox(height: 80),
                  const FeaturesSection(),
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
}

// Header Component
class WebHeader extends StatelessWidget {
  const WebHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 768 && screenWidth <= 1200;
        final isMobile = screenWidth <= 768;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 16
                : isTablet
                    ? 40
                    : 80,
            vertical: isMobile ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: isMobile
              ? _buildMobileHeader(context)
              : _buildDesktopHeader(isTablet, context),
        );
      },
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      children: [
        // Top row with logo and menu button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      const Icon(Icons.computer, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'GizmoGlobe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            // Action buttons
            Row(
              children: [
                _buildIconButton(Icons.chat_bubble_outline, isMobile: true,
                    onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen.newInstance(),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                _buildIconButton(Icons.shopping_cart_outlined, isMobile: true),
                const SizedBox(width: 8),
                _buildIconButton(Icons.person_outline, isMobile: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search,
                  color: Colors.white.withOpacity(0.4), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.0),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                      height: 1.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Navigation Links
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavLink('Products'),
            _buildNavLink('Categories'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(bool isTablet, BuildContext context) {
    return Row(
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: isTablet ? 36 : 40,
              height: isTablet ? 36 : 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.computer,
                color: Colors.white,
                size: isTablet ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'GizmoGlobe',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(width: isTablet ? 40 : 60),
        // Navigation Links
        Expanded(
          child: Row(
            children: [
              _buildNavLink('Products'),
              SizedBox(width: isTablet ? 24 : 32),
              _buildNavLink('Categories'),
            ],
          ),
        ),
        // Search Bar
        Container(
          width: isTablet ? 280 : 320,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search,
                  color: Colors.white.withOpacity(0.4), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.0),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                      height: 1.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Action Buttons
        _buildIconButton(Icons.chat_bubble_outline, onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen.newInstance(),
            ),
          );
        }),
        const SizedBox(width: 16),
        _buildIconButton(Icons.shopping_cart_outlined),
        const SizedBox(width: 16),
        _buildIconButton(Icons.person_outline),
      ],
    );
  }

  Widget _buildNavLink(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildIconButton(IconData icon,
      {bool isMobile = false, VoidCallback? onPressed}) {
    final size = isMobile ? 32.0 : 40.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: iconSize),
      ),
    );
  }
}

// Hero Section
class HeroSection extends StatelessWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          // Main Hero Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Content
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        '🎉 New Arrivals',
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Build Your\nDream PC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Premium PC components and peripherals for gamers,\ncreators, and professionals. Free shipping on orders over \$99.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Shop Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 20),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Deals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              // Right Stats Cards
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatCard(
                      '50K+',
                      'Products',
                      'Latest PC components',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      '24/7',
                      'Support',
                      'Expert assistance',
                      Icons.support_agent_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      '2-Day',
                      'Shipping',
                      'Fast & reliable',
                      Icons.local_shipping_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Category Navigation
class CategoryNav extends StatelessWidget {
  const CategoryNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view},
      {'name': 'CPUs', 'icon': Icons.memory},
      {'name': 'GPUs', 'icon': Icons.videogame_asset},
      {'name': 'Motherboards', 'icon': Icons.developer_board},
      {'name': 'RAM', 'icon': Icons.storage},
      {'name': 'Storage', 'icon': Icons.save},
      {'name': 'Cooling', 'icon': Icons.ac_unit},
      {'name': 'Cases', 'icon': Icons.computer},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCategoryButton(
              category['name'] as String,
              category['icon'] as IconData,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryButton(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Best Sellers Section
class BestSellersSection extends StatelessWidget {
  final List<Product> products;

  const BestSellersSection({Key? key, required this.products})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Best Sellers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top-rated products loved by our customers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductScreen.newInstance(
                        initialSortOption: SortEnum.salesHighest,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          ),
        ],
      ),
    );
  }
}

// Favorites Section
class FavoritesSection extends StatelessWidget {
  final List<Product> products;

  const FavoritesSection({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Favorites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Highly recommended by the community',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductScreen.newInstance(
                        initialProducts: products,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF06B6D4),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF06B6D4),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          ),
        ],
      ),
    );
  }
}

// Product Card Component
class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered
                ? const Color(0xFF8B5CF6).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isHovered ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          widget.product.imageUrl ??
                              'https://via.placeholder.com/400x300',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.productName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFBBF24), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.product.sales})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Features Section
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        children: [
          Expanded(
            child: _buildFeature(
              Icons.local_shipping_outlined,
              'Free Shipping',
              'On orders over \$99',
            ),
          ),
          Expanded(
            child: _buildFeature(
              Icons.verified_user_outlined,
              '2-Year Warranty',
              'On all products',
            ),
          ),
          Expanded(
            child: _buildFeature(
              Icons.support_agent_outlined,
              '24/7 Support',
              'Expert assistance',
            ),
          ),
          Expanded(
            child: _buildFeature(
              Icons.lock_outline,
              'Secure Payment',
              'SSL encrypted',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Footer Component
class WebFooter extends StatelessWidget {
  const WebFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Description
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.computer,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'GizmoGlobe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your trusted source for premium\nPC components and peripherals.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              // Links Columns
              Expanded(
                child: _buildFooterColumn('Shop', [
                  'All Products',
                  'Best Sellers',
                  'New Arrivals',
                  'Deals',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn('Support', [
                  'Help Center',
                  'Contact Us',
                  'Shipping Info',
                  'Returns',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn('Company', [
                  'About Us',
                  'Careers',
                  'Press',
                  'Blog',
                ]),
              ),
              Expanded(
                child: _buildFooterColumn('Legal', [
                  'Privacy Policy',
                  'Terms of Service',
                  'Cookie Policy',
                  'Disclaimer',
                ]),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 GizmoGlobe. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  _buildSocialIcon(Icons.facebook),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.camera_alt),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.close), // X/Twitter
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.play_arrow),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                link,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
    );
  }
}
