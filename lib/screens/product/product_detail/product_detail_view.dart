import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';

import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../functions/helper.dart';
import '../../../generated/l10n.dart';
import '../../../objects/product_related/cpu_related/cpu.dart';
import '../../../objects/product_related/drive_related/drive.dart';
import '../../../objects/product_related/gpu_related/gpu.dart';
import '../../../objects/product_related/mainboard_related/mainboard.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/psu_related/psu.dart';
import '../../../objects/product_related/ram_related/ram.dart';
import '../../../services/recommendation_service.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/field_with_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listener: (context, state) {
        if (state.processState == ProcessState.success) {
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
        } else if (state.processState == ProcessState.failure) {
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
                            color: Colors.red,
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
                          Stack(
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.1)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                    image: state.product.imageUrl != null
                                        ? DecorationImage(
                                      image: NetworkImage(
                                          state.product.imageUrl!),
                                      fit: BoxFit.contain,
                                    )
                                        : null,
                                  ),
                                  child: state.product.imageUrl == null ?
                                    Center(
                                      child: Icon(
                                        _getCategoryIcon(),
                                        size: 100,
                                        color: Theme.of(context).brightness ==
                                            Brightness.dark
                                            ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.7)
                                            : Colors.grey[600],
                                          ),
                                    ) : null
                                ),
                              ),
                              Positioned(
                                right: 24,
                                bottom: 24,
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  onPressed: () {
                                    if (state.product.productID != null) {
                                      cubit.toggleFavorite();
                                      context
                                          .read<FavoritesCubit>()
                                          .loadFavorites();
                                    }
                                  },
                                  child: Icon(
                                    state.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: state.isFavorite
                                        ? Colors.red[400]
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),

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
                                            Helper.toCurrencyFormat(widget.product.price),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[700],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-${widget.product.discount.toStringAsFixed(0)}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      Helper.toCurrencyFormat(widget.product.discountedPrice),
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
                                ..._buildProductSpecificDetails(context, state.product, state.technicalSpecs),
                                const SizedBox(height: 24),

                                // if (widget.product.getDescription(context) != null) ...[
                                //   const SizedBox(height: 12),
                                //   _buildTextField(context, S.of(context).description,
                                //       widget.product.getDescription(context)!),
                                // ],

                                _buildRecommendationsSection(context, state.product),
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                                const SizedBox(height: 36),
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
                                      Helper.toCurrencyFormat(widget.product.price * state.quantity),
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
                                      (Helper.toCurrencyFormat(widget.product.discountedPrice * state.quantity)),
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
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add to Cart', // 'Thêm vào giỏ'
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
    return specs.entries
        .map((entry) => _buildSpecificationRow(
        _getLocalizedSpecKey(context, entry.key), entry.value))
        .toList();
  }

  String _getLocalizedSpecKey(BuildContext context, String key) {
    switch (key.toLowerCase()) {
      case 'type':
        return S.of(context).driveType;
      case 'capacity':
        // return S.of(context).driveCapacity;
        return "Drive Capacity";
      case 'ram bus':
        // return S.of(context).ramBus;
        return "RAM Bus";
      case 'ram capacity':
        // return S.of(context).ramCapacity;
        return "RAM Capacity";
      case 'ram type':
        return S.of(context).ramType;
      case 'cpu family':
        // return S.of(context).cpuFamily;
        return "CPU Family";
      case 'cpu core':
        return S.of(context).cpuCore;
      case 'cpu thread':
        return S.of(context).cpuThread;
      case 'cpu clock speed':
        return S.of(context).cpuClockSpeed;
      case 'psu wattage':
        return S.of(context).psuWattage;
      case 'psu efficiency':
        // return S.of(context).psuEfficiency;
        return "PSU Efficiency";
      case 'psu modular':
        // return S.of(context).psuModular;

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
      case 'form factor':
        return S.of(context).formFactor;
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
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
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, Product currentProduct) {
    final recs = RecommendationService()
        .getCompatibleForProduct(currentProduct)
        .where((p) => p.productID != currentProduct.productID)
        .toList();

    if (recs.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good with this product',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            const int crossAxisCount = 2;
            const double spacing = 8.0;
            const double itemHeight = 260.0;

            final totalSpacing = spacing * (crossAxisCount - 1);
            final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
            final childAspectRatio = itemWidth / itemHeight;

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final product = recs[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ProductDetailScreen.newInstance(product),
                      ),
                    );
                  },
                  child: ProductCard(product: product),
                );
              },
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

