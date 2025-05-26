import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';

import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../generated/l10n.dart';
import '../../../objects/product_related/cpu.dart';
import '../../../objects/product_related/drive.dart';
import '../../../objects/product_related/gpu.dart';
import '../../../objects/product_related/mainboard.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/psu.dart';
import '../../../objects/product_related/ram.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/product/favorites/favorites_cubit.dart';
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
                              color: Theme.of(context).colorScheme.onPrimary,
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
                                            .withOpacity(0.1)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getCategoryIcon(),
                                      size: 100,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.7)
                                          : Colors.grey[600],
                                    ),
                                  ),
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
                                            '\$${widget.product.price.toStringAsFixed(2)}',
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
                                              '-${widget.product.discountPercentage.toStringAsFixed(0)}%',
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
                                      '\$${widget.product.discountedPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildSpecificationList(context),
                                const SizedBox(height: 24),
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
                          color: Colors.black.withOpacity(0.2),
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
                                  'Quantity', // 'Số lượng'
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
                                  'Total Price', // 'Tổng tiền'
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
                                      '\$${(widget.product.price * state.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface.withValues(alpha: 0.6),
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
                                      '\$${(widget.product.discountedPrice * state.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
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
                              backgroundColor: Theme.of(context).primaryColor,
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

  Widget _buildSpecificationList(BuildContext context) {
    final specs = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          S.of(context).productSpecifications,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      _buildSpecGroup(
        S.of(context).basicInformation,
        [
          _buildSpecRow(context, S.of(context).manufacturer,
              widget.product.manufacturer.manufacturerName)
        ],
      ),
    ];

    switch (widget.product.runtimeType) {
      case const (RAM):
        final ram = widget.product as RAM;
        specs.add(_buildSpecGroup(
          S.of(context).memorySpecifications,
          [
            _buildSpecRow(context, S.of(context).busSpeed, '${ram.bus}'),
            _buildSpecRow(
                context, S.of(context).capacity, '${ram.capacity}'),
            _buildSpecRow(
                context, S.of(context).ramType, ram.ramType.toString()),
          ],
        ));
        break;
      case const (CPU):
        final cpu = widget.product as CPU;
        specs.add(_buildSpecGroup(
          S.of(context).processorSpecifications,
          [
            _buildSpecRow(context, S.of(context).family, cpu.family.toString()),
            _buildSpecRow(context, S.of(context).cores,
                '${cpu.core}'),
            _buildSpecRow(context, S.of(context).threads,
                '${cpu.thread}'),
            _buildSpecRow(
                context, S.of(context).clockSpeed, '${cpu.clockSpeed} GHz'),
          ],
        ));
        break;
      case const (PSU):
        final psu = widget.product as PSU;
        specs.add(_buildSpecGroup(
          S.of(context).powerSupplySpecifications,
          [
            _buildSpecRow(
                context, S.of(context).wattage, '${psu.wattage}W'),
            _buildSpecRow(
                context, S.of(context).efficiency, psu.efficiency.toString()),
            _buildSpecRow(
                context, S.of(context).modular, psu.modular.toString()),
          ],
        ));
        break;
      case const (GPU):
        final gpu = widget.product as GPU;
        specs.add(_buildSpecGroup(
          S.of(context).graphicsCardSpecifications,
          [
            _buildSpecRow(context, S.of(context).series, gpu.series.toString()),
            _buildSpecRow(
                context, S.of(context).memory, gpu.capacity.toString()),
            _buildSpecRow(context, S.of(context).busWidth, gpu.bus.toString()),
            _buildSpecRow(
                context, S.of(context).clockSpeed, '${gpu.clockSpeed.toString()}GHz'),
          ],
        ));
        break;
      case const (Mainboard):
        final mainboard = widget.product as Mainboard;
        specs.add(_buildSpecGroup(
          S.of(context).motherboardSpecifications,
          [
            _buildSpecRow(context, S.of(context).formFactor,
                mainboard.formFactor.toString()),
            _buildSpecRow(
                context, S.of(context).series, mainboard.series.toString()),
            _buildSpecRow(context, S.of(context).compatibility,
                mainboard.compatibility.toString()),
          ],
        ));
        break;
      case const (Drive):
        final drive = widget.product as Drive;
        specs.add(_buildSpecGroup(
          S.of(context).storageSpecifications,
          [
            _buildSpecRow(
                context, S.of(context).driveType, drive.type.toString()),
            _buildSpecRow(
                context, S.of(context).capacity, drive.capacity.toString()),
          ],
        ));
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: specs,
      ),
    );
  }

  Widget _buildSpecGroup(String title, List<Widget> specs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: specs,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpecRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection({
    required double sellingPrice,
    required double discount,
  }) {
    final discountedPrice = sellingPrice * (1 - discount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 8),
          const Text(
            'Price: ', // 'Giá: '
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (discount > 0) ...[
            Text(
              '\$${sellingPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.lineThrough,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${discountedPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.green[300],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${(discount * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else
            Text(
              '\$${sellingPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
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
    }
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).primaryColor),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        splashRadius: 20,
      ),
    );
  }
}
