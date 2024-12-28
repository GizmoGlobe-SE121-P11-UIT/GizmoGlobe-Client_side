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
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.product.discount > 0) ...[
                                  Row(
                                    children: [
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
                                          color: Colors.red[700],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '-${widget.product.discountPercentage.toStringAsFixed(0)}%',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
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
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildQuantityButton(
                                    icon: Icons.remove,
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() => quantity--);
                                      }
                                    },
                                  ),
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _buildQuantityButton(
                                    icon: Icons.add,
                                    onPressed: () {
                                      setState(() => quantity++);
                                    },
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
                              'Total Price',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${(widget.product.discountedPrice * quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
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
                            context.read<CartScreenCubit>().addToCart(
                              widget.product.productID!,
                              quantity,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${widget.product.productName} to cart',
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(16),
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
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
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
          ),
        );
      },
    );
  }

  Widget _buildSpecificationList(BuildContext context) {
    final specs = <Widget>[
      const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Text(
          'Product Specifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      _buildSpecGroup(
        'Basic Information',
        [_buildSpecRow('Manufacturer', widget.product.manufacturer.manufacturerName)],
      ),
    ];

    switch (widget.product.runtimeType) {
      case RAM:
        final ram = widget.product as RAM;
        specs.add(_buildSpecGroup(
          'Memory Specifications',
          [
            _buildSpecRow('Bus Speed', '${ram.bus} MHz'),
            _buildSpecRow('Capacity', '${ram.capacity} GB'),
            _buildSpecRow('RAM Type', ram.ramType.toString()),
          ],
        ));
        break;
      case CPU:
        final cpu = widget.product as CPU;
        specs.add(_buildSpecGroup(
          'Processor Specifications',
          [
            _buildSpecRow('Family', cpu.family.toString()),
            _buildSpecRow('Cores', '${cpu.core} Cores'),
            _buildSpecRow('Threads', '${cpu.thread} Threads'),
            _buildSpecRow('Clock Speed', '${cpu.clockSpeed} GHz'),
          ],
        ));
        break;
      case PSU:
        final psu = widget.product as PSU;
        specs.add(_buildSpecGroup(
          'Power Supply Specifications',
          [
            _buildSpecRow('Wattage', psu.wattage.toString()),
            _buildSpecRow('Efficiency', psu.efficiency.toString()),
            _buildSpecRow('Modular', psu.modular.toString()),
          ],
        ));
        break;
      case GPU:
        final gpu = widget.product as GPU;
        specs.add(_buildSpecGroup(
          'Graphics Card Specifications',
          [
            _buildSpecRow('Series', gpu.series.toString()),
            _buildSpecRow('Memory', gpu.capacity.toString()),
            _buildSpecRow('Bus Width', gpu.bus.toString()),
            _buildSpecRow('Clock Speed', gpu.clockSpeed.toString()),
          ],
        ));
        break;
      case Mainboard:
        final mainboard = widget.product as Mainboard;
        specs.add(_buildSpecGroup(
          'Motherboard Specifications',
          [
            _buildSpecRow('Form Factor', mainboard.formFactor.toString()),
            _buildSpecRow('Series', mainboard.series.toString()),
            _buildSpecRow('Compatibility', mainboard.compatibility.toString()),
          ],
        ));
        break;
      case Drive:
        final drive = widget.product as Drive;
        specs.add(_buildSpecGroup(
          'Storage Specifications',
          [
            _buildSpecRow('Drive Type', drive.type.toString()),
            _buildSpecRow('Capacity', drive.capacity.toString()),
          ],
        ));
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...specs,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
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

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
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