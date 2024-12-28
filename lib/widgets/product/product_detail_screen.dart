import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../objects/product_related/product.dart';
import '../../objects/product_related/ram.dart';
import '../../objects/product_related/cpu.dart';
import '../../objects/product_related/psu.dart';
import '../../objects/product_related/gpu.dart';
import '../../objects/product_related/drive.dart';
import '../../objects/product_related/mainboard.dart';
import '../../enums/product_related/category_enum.dart';
import '../../screens/cart/cart_screen/cart_screen_cubit.dart';
import '../../screens/cart/cart_screen/cart_screen_state.dart';
import '../../screens/cart/cart_screen/cart_screen_view.dart';
import '../general/gradient_icon_button.dart';
import 'favorites/favorites_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favorites) {
        final isFavorite = widget.product.productID != null &&
                          favorites.contains(widget.product.productID);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
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
                    icon: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
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
                            style: const TextStyle(
                              color: Colors.white,
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
          body: Column(
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
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(),
                                  size: 100,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 24,
                            bottom: 24,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.white,
                              onPressed: () {
                                if (widget.product.productID != null) {
                                  context.read<FavoritesCubit>().toggleFavorite(
                                    widget.product.productID!,
                                  );
                                }
                              },
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.productName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (widget.product.discount > 0) ...[
                                  Text(
                                    '\$${widget.product.price.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red[100]!),
                                    ),
                                    child: Text(
                                      '-${widget.product.discountPercentage.toStringAsFixed(0)}%',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '\$${widget.product.discountedPrice.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Product specifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            const Text(
                              'Amount',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[700]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white),
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setState(() => quantity--);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 16,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: () {
                                        setState(() => quantity++);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${(widget.product.discountedPrice * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.product.productID != null) {
                            context.read<CartScreenCubit>().addToCart(
                              widget.product.productID!,
                              quantity,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${widget.product.productName} to cart',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot add product to cart'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add to cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecificationList(BuildContext context) {
    final specs = <Widget>[
      _buildSpecRow('Manufacturer', widget.product.manufacturer.manufacturerName),
    ];

    switch (widget.product.runtimeType) {
      case RAM:
        final ram = widget.product as RAM;
        specs.addAll([
          _buildSpecRow('Bus Speed', ram.bus.toString()),
          _buildSpecRow('Capacity', ram.capacity.toString()),
          _buildSpecRow('RAM Type', ram.ramType.toString()),
        ]);
        break;
      case CPU:
        final cpu = widget.product as CPU;
        specs.addAll([
          _buildSpecRow('Family', cpu.family.toString()),
          _buildSpecRow('Cores', '${cpu.core}'),
          _buildSpecRow('Threads', '${cpu.thread}'),
          _buildSpecRow('Clock Speed', cpu.clockSpeed.toString()),
        ]);
        break;
      case PSU:
        final psu = widget.product as PSU;
        specs.addAll([
          _buildSpecRow('Wattage', psu.wattage.toString()),
          _buildSpecRow('Efficiency', psu.efficiency.toString()),
          _buildSpecRow('Modular', psu.modular.toString()),
        ]);
        break;
      case GPU:
        final gpu = widget.product as GPU;
        specs.addAll([
          _buildSpecRow('Series', gpu.series.toString()),
          _buildSpecRow('Memory', gpu.capacity.toString()),
          _buildSpecRow('Bus Width', gpu.bus.toString()),
          _buildSpecRow('Clock Speed', gpu.clockSpeed.toString()),
        ]);
        break;
      case Mainboard:
        final mainboard = widget.product as Mainboard;
        specs.addAll([
          _buildSpecRow('Form Factor', mainboard.formFactor.toString()),
          _buildSpecRow('Series', mainboard.series.toString()),
          _buildSpecRow('Compatibility', mainboard.compatibility.toString()),
        ]);
        break;
      case Drive:
        final drive = widget.product as Drive;
        specs.addAll([
          _buildSpecRow('Drive Type', drive.type.toString()),
          _buildSpecRow('Capacity', drive.capacity.toString()),
        ]);
        break;
    }

    return Column(
      children: specs,
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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
      default:
        return Icons.devices_other;
    }
  }
}