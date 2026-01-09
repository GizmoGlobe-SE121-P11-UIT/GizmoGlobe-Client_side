import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';

import '../../../components/general/snackbar_service.dart';
import '../../../components/general/web_product_card.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../functions/helper.dart';
import '../../../widgets/order/rating_card.dart';
import '../../../generated/l10n.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/mainboard_related/mainboard.dart';
import '../../../services/recommendation_service.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
import '../../../widgets/product/product_card.dart';
import '../../cart/cart_screen/cart_screen_cubit.dart';
import '../../cart/cart_screen/cart_screen_state.dart';
import '../../cart/cart_screen/cart_screen_view.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  static Widget newInstance(Product product) => BlocProvider(
        create: (context) => ProductDetailCubit(product),
        child: ProductDetailScreen(product: product),
      );

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetailCubit get cubit => context.read<ProductDetailCubit>();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // @override
  // void dispose() {
  //   _pageController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listener: (context, state) {
        if (state.processState == ProcessState.success) {
          // Check if it's a cart addition success
          if (state.message == 'CART_ADDED') {
            SnackbarService.showCartSuccess(
              context,
              widget.product.productName,
            );
            cubit.setIdleState();
          } else {
            // Other success cases (like order placed) show dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InformationDialog(
                title: S.of(context).orderPlaced,
                content: state.message,
                dialogName: DialogName.success,
                buttonText: S.of(context).ok,
                onPressed: () {
                  Navigator.pop(context);
                  cubit.setIdleState();
                },
              ),
            );
          }
        } else if (state.processState == ProcessState.failure) {
          // Handle cart-related failures with localized messages
          if (state.message == 'CART_ERROR') {
            SnackbarService.showCartError(context);
            cubit.setIdleState();
          } else if (state.message == 'CART_LOGIN_REQUIRED') {
            SnackbarService.showGuestRestriction(
              context,
              actionType: 'cart',
            );
            cubit.setIdleState();
          } else {
            // Other failure cases show dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InformationDialog(
                title: S.of(context).error,
                content: state.message,
                dialogName: DialogName.failure,
                buttonText: S.of(context).ok,
                onPressed: () {
                  Navigator.pop(context);
                  cubit.setIdleState();
                },
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state.processState == ProcessState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: GradientIconButton(
              icon: Icons.chevron_left,
              onPressed: () {
                Navigator.pop(context);
              },
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen.newInstance(),
                        ),
                      );
                    },
                  ),
                  BlocBuilder<CartScreenCubit, CartScreenState>(
                    builder: (context, state) {
                      if (state.itemCount == 0) return const SizedBox();
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            state.itemCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageCarousel(context, state),

                          // Product Info Section
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.productName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.product.discount > 0) ...[
                                      Row(
                                        children: [
                                          Text(
                                            Helper.toCurrencyFormat(
                                                widget.product.price),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-${widget.product.discount.toStringAsFixed(0)}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onError,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      Helper.toCurrencyFormat(
                                          widget.product.discountedPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._buildProductSpecificDetails(context,
                                    state.product, state.technicalSpecs),
                                const SizedBox(height: 24),

                                // if (widget.product.getDescription(context) != null) ...[
                                //   const SizedBox(height: 12),
                                //   _buildTextField(context, S.of(context).description,
                                //       widget.product.getDescription(context)!),
                                // ],
                                const SizedBox(height: 24),
                                _buildRatingSection(state),
                                const SizedBox(height: 24),
                                _buildRecommendationsSection(
                                    context, state.product),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  S.of(context).quantity, // 'Số lượng'
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${S.of(context).inStock}: ${state.product.stock}',
                                  style: TextStyle(
                                    color: state.product.stock > 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7)
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6)),
                                    borderRadius: BorderRadius.circular(8),
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildQuantityButton(
                                        icon: Icons.remove,
                                        onPressed: () =>
                                            cubit.decrementQuantity(),
                                      ),
                                      Container(
                                        width: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          state.quantity.toString(),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      _buildQuantityButton(
                                        icon: Icons.add,
                                        onPressed: () =>
                                            cubit.incrementQuantity(),
                                        enabled: state.quantity <
                                            state.product.stock,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  S.of(context).totalPrice, // 'Tổng tiền'
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      Helper.toCurrencyFormat(
                                          widget.product.price *
                                              state.quantity),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      (Helper.toCurrencyFormat(
                                          widget.product.discountedPrice *
                                              state.quantity)),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.product.productID != null) {
                                cubit.addToCart(
                                  widget.product.productID!,
                                  state.quantity,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              S.of(context).addToCart,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.product.category) {
      case CategoryEnum.ram:
        return Icons.memory;
      case CategoryEnum.cpu:
        return Icons.developer_board;
      case CategoryEnum.gpu:
        return Icons.videocam;
      case CategoryEnum.psu:
        return Icons.power;
      case CategoryEnum.drive:
        return Icons.storage;
      case CategoryEnum.mainboard:
        return Icons.dashboard;
      default:
        return Icons.devices;
    }
  }

  List<Widget> _buildProductSpecificDetails(
      BuildContext context, Product product, Map<String, String> specs) {
    return specs.entries.map((entry) {
      String value = entry.value;
      // Format RAM Spec with localization if it's a Mainboard
      if (entry.key == 'RAM Spec' &&
          product.category == CategoryEnum.mainboard) {
        final mainboard = product as Mainboard;
        value = mainboard.ramSpec.toLocalizedString(S.of(context));
      }
      return _buildSpecificationRow(
          _getLocalizedSpecKey(context, entry.key), value);
    }).toList();
  }

  String _getLocalizedSpecKey(BuildContext context, String key) {
    switch (key.toLowerCase()) {
      case 'type':
      case 'drive type':
        return S.of(context).driveType;
      case 'capacity':
        return S.of(context).driveCapacity;
      case 'generation':
        return S.of(context).driveGeneration;
      case 'interface':
        return S.of(context).driveInterface;
      case 'read speed':
        return S.of(context).readSpeed;
      case 'write speed':
        return S.of(context).writeSpeed;
      case 'ram bus':
        return S.of(context).ramBus;
      case 'capacity per stick':
        return S.of(context).capacityPerStick;
      case 'ram capacity':
        return S.of(context).ramCapacity;
      case 'ram type':
        return S.of(context).ramType;
      case 'cl latency':
        return S.of(context).clLatency;
      case 'kit stick count':
        return S.of(context).kitStickCount;
      case 'cpu family':
        // return S.of(context).cpuFamily;
        return "CPU Family";
      case 'cpu core':
      case 'cores':
        return S.of(context).cpuCore;
      case 'cpu thread':
      case 'threads':
        return S.of(context).cpuThread;
      case 'cpu clock speed':
      case 'base clock':
        return S.of(context).cpuClockSpeed;
      case 'turbo clock':
        return "Turbo Clock";
      case 'tdp':
        return "TDP";
      case 'socket':
        return S.of(context).compatibility;
      case 'psu wattage':
        return S.of(context).psuWattage;
      case 'psu efficiency':
        return S.of(context).psuEfficiency;
      case 'psu modular':
        return S.of(context).psuModular;
      case 'connectors':
        return S.of(context).connectors;

      case 'gpu series':
        // return S.of(context).gpuSeries;
        return "GPU Series";
      case 'gpu capacity':
        // return S.of(context).gpuCapacity;
        return "GPU Capacity";
      case 'gpu bus':
        // return S.of(context).gpuBus;
        return "GPU Bus";
      case 'gpu clock speed':
        return S.of(context).gpuClockSpeed;
      case 'chipset':
        return S.of(context).chipset;
      case 'form factor':
        return S.of(context).formFactor;
      case 'ram spec':
        return S.of(context).ramSpec;
      case 'storage:':
        return S.of(context).storageSlots;
      case 'pcie slots:':
        return S.of(context).pcieSlots;
      case 'i/o ports:':
        return S.of(context).ioPorts;
      case 'series':
        return S.of(context).series;
      case 'compatibility':
        return S.of(context).compatibility;
      default:
        return key;
    }
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(
          icon,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, ProductDetailState state) {
    final hasImages = state.productImages.isNotEmpty;

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: state.isLoadingImages
                ? const Center(child: CircularProgressIndicator())
                : hasImages
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.productImages.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            }
                          },
                          itemBuilder: (context, index) {
                            final image = state.productImages[index];
                            return Image.network(
                              image.url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getCategoryIcon(),
                                    size: 100,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.7)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getCategoryIcon(),
                          size: 100,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
        ),
        // Page indicator dots
        if (hasImages && state.productImages.length > 1)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                state.productImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        // Favorite button
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onPressed: () {
              if (state.product.productID != null) {
                cubit.toggleFavorite();
                context.read<FavoritesCubit>().loadFavorites();
              }
            },
            child: Icon(
              state.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: state.isFavorite
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
      BuildContext context, Product currentProduct) {
    return FutureBuilder<List<Product>>(
      future: RecommendationService().getSimilarProducts(
        currentProduct,
        topN: 6,
        excludeOutOfStock: false,
      ),
      builder: (context, snapshot) {
        // Get compatible products (cross-category) synchronously
        final compatibleProducts = RecommendationService()
            .getCompatibleForProduct(currentProduct, topN: 6)
            .where((p) => p.productID != currentProduct.productID)
            .toList();

        // Loading state for similar products
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show compatible products while loading similar products
          if (compatibleProducts.isEmpty) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
        }

        // Get similar products (same category, AI-powered)
        final similarProducts =
            (snapshot.hasData ? snapshot.data! : <Product>[])
                .where((p) => p.productID != currentProduct.productID)
                .toList();

        // Combine both lists (similar first, then compatible)
        final allRecommendations = <Product>[
          ...similarProducts,
          ...compatibleProducts,
        ];

        // Remove duplicates based on productID
        final seenIds = <String>{};
        final uniqueRecommendations = allRecommendations.where((product) {
          if (product.productID == null) return false;
          if (seenIds.contains(product.productID!)) return false;
          seenIds.add(product.productID!);
          return true;
        }).toList();

        if (uniqueRecommendations.isEmpty) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).goodWithThisProduct,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (context, constraints) {
                const int crossAxisCount = !kIsWeb ? 2 : 4;
                const double spacing = 8.0;
                const double itemHeight = 260.0;

                final totalSpacing = spacing * (crossAxisCount - 1);
                final itemWidth =
                    (constraints.maxWidth - totalSpacing) / crossAxisCount;
                final childAspectRatio = itemWidth / itemHeight;

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: uniqueRecommendations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final product = uniqueRecommendations[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                ProductDetailScreen.newInstance(product),
                          ),
                        );
                      },
                      child: !kIsWeb
                          ? ProductCard(product: product)
                          : WebProductCard(product: product),
                    );
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Ratings section for mobile product detail
  Widget _buildRatingSection(ProductDetailState state) {
    final ratings = state.ratings;
    final hasRatings = ratings.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).ratingsAndReviews,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),

        // Average summary (no highlight)
        Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      (state.averageRating > 0)
                          ? state.averageRating.toStringAsFixed(1)
                          : '0.0',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (state.totalRatingsCount > 0)
                          ? S.of(context).reviews(state.totalRatingsCount)
                          : S.of(context).noRatingsYet,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Individual rating cards
        if (!hasRatings)
          const SizedBox()
        else
          Column(
            children: ratings.map((r) => RatingCard(rating: r)).toList(),
          ),
        // Show more button
        if (state.hasMoreRatings)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await cubit.loadMoreRatings();
                },
                child: Text(S.of(context).showMore),
              ),
            ),
          ),
      ],
    );
  }
}
