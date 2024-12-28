import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/cart/address_screen/choose_address_screen_view.dart';
import 'package:gizmoglobe_client/services/stripe_services.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../objects/address_related/address.dart';
import '../../../objects/product_related/product.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/gradient_text.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../user/address_screen/address_screen_view.dart';
import '../cart_screen/cart_screen_view.dart';
import 'checkout_screen_cubit.dart';
import 'checkout_screen_state.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<Product, int>> cartItems;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
  });

  static Widget newInstance({required List<Map<Product, int>> cartItems}) =>
    BlocProvider(
      create: (context) => CheckoutScreenCubit(),
      child: CheckoutScreen(cartItems: cartItems),
    );

  @override
  State<CheckoutScreen> createState() => _CheckoutScreen();
}

class _CheckoutScreen extends State<CheckoutScreen> {
  CheckoutScreenCubit get cubit => context.read<CheckoutScreenCubit>();

  @override
  void initState() {
    super.initState();
    cubit.initialize(widget.cartItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const GradientText(text: 'Checkout'),
      ),
      body: BlocConsumer<CheckoutScreenCubit, CheckoutScreenState>(
        listener: (context, state) {
          if (state.processState == ProcessState.success) {
            {
              showDialog(
                context: context,
                builder: (context) =>
                    InformationDialog(
                      title: 'Order Placed',
                      content: 'Your order has been placed successfully',
                      onPressed: () =>
                      {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartScreen.newInstance(),
                          ),
                        ),
                      },
                    ),
              );
            }
          };
        },
        builder: (context, state) {
          if (state.processState == ProcessState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.processState == ProcessState.failure) {
            return Center(child: Text(state.error ?? 'Error loading checkout'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.salesInvoice?.details.length ?? 0,
                  itemBuilder: (context, index) {
                    final detail = state.salesInvoice!.details[index];
                    final product = detail.product;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(product.category),
                                  size: 36,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.productName,
                                  style: AppTextStyle.boldText,
                                ),
                                const SizedBox(height: 4),
                                if (product.discount > 0) ...[
                                  Text(
                                    '\$${(product.price*detail.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  '\$${(detail.sellingPrice*detail.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[200],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                constraints: const BoxConstraints(minWidth: 16),
                                alignment: Alignment.center,
                                child: Text(
                                  'x${detail.quantity}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.boldText,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipping Address',
                        style: AppTextStyle.boldText,
                      ),
                      GestureDetector(
                        onTap: () async {
                          Address address = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChooseAddressScreen.newInstance(address: state.salesInvoice!.address!)),
                          );

                          if (address != Address.nullAddress) {
                            cubit.updateAddress(address);
                          }
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                state.salesInvoice?.address == Address.nullAddress ?
                                const Center(
                                  child: Text(
                                    'Choose Address',
                                    style: AppTextStyle.regularText,
                                  ),
                                ) :
                                Text(
                                  state.salesInvoice!.address!.firstLine(),
                                  style: AppTextStyle.boldText,
                                ),
                                if (state.salesInvoice?.address != Address.nullAddress)
                                  Text(
                                    state.salesInvoice!.address!.secondLine(),
                                    style: AppTextStyle.regularText,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            GradientText(text: 'Total cost'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (state.salesInvoice!.hasDiscount()) ...[
                              Text(
                                '\$${state.salesInvoice?.getTotalBasedPrice().toStringAsFixed(2)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              '\$${state.salesInvoice?.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                        onPressed: () async {
                          if (state.salesInvoice?.address == Address.nullAddress) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an address')));
                            return;
                          }
                          await cubit.checkout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Place Order',
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
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return Icons.memory;
      case CategoryEnum.cpu:
        return Icons.developer_board;
      case CategoryEnum.gpu:
        return Icons.videocam;
      case CategoryEnum.psu:
        return Icons.power;
      case CategoryEnum.mainboard:
        return Icons.storage;
      case CategoryEnum.mainboard:
        return Icons.dashboard;
      default:
        return Icons.devices_other;
    }
  }
}