import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/order_option_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../objects/address_related/address.dart';
import '../../../objects/product_related/product.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/gradient_text.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../user/order_screen/order_screen_view.dart';
import '../choose_address_screen/choose_address_screen_view.dart';
import '../../../generated/l10n.dart';
import '../choose_voucher_screen/choose_voucher_screen_view.dart';
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
        title: GradientText(text: S.of(context).checkoutTitle),
      ),
      body: BlocConsumer<CheckoutScreenCubit, CheckoutScreenState>(
        listener: (context, state) {
          if (state.processState == ProcessState.success) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InformationDialog(
                title: S.of(context).orderPlaced,
                content: S.of(context).orderPlacedSuccess,
                dialogName: DialogName.success,
                buttonText: S.of(context).ok,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderScreen.newInstance(
                        orderOption: OrderOption.toShip,
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
            );
          } else if (state.processState == ProcessState.failure) {
            String errorMessage = S.of(context).errorCheckout;

            if ((state.message.toLowerCase().contains('payment failed') ||
                    state.message.toLowerCase().contains('stripe'))) {
              errorMessage = S.of(context).paymentCancelled;
            }

            showDialog(
              context: context,
              builder: (context) => InformationDialog(
                title: S.of(context).paymentStatus,
                content: errorMessage,
                dialogName: DialogName.failure,
                buttonText: S.of(context).tryAgain,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.processState == ProcessState.loading) {
            return const Center(child: CircularProgressIndicator());
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
                                    '\$${(product.price * detail.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  '\$${(detail.sellingPrice * detail.quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                      Text(
                        'Vouchers',
                        style: AppTextStyle.boldText,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final voucher = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChooseVoucherScreen.newInstance(
                                totalAmount: state.salesInvoice!.getTotalBasedPrice(),
                                currentVoucher: state.salesInvoice!.voucher,
                              ),
                            ),
                          );

                          if (voucher != null) {
                            cubit.updateVoucher(voucher);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: state.salesInvoice?.voucher == null
                                    ? Text(
                                  'Add Voucher',
                                  style: AppTextStyle.regularText,
                                )
                                    : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.salesInvoice!.voucher!.voucherName,
                                      style: AppTextStyle.boldText,
                                    ),
                                    if (state.salesInvoice!.voucherDiscount > 0)
                                      Text(
                                        '- \$${state.salesInvoice!.voucherDiscount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      Text(
                        S.of(context).shippingAddress,
                        style: AppTextStyle.boldText,
                      ),
                      GestureDetector(
                        onTap: () async {
                          Address address = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ChooseAddressScreen.newInstance(
                                        address: state.salesInvoice!.address!)),
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
                                state.salesInvoice?.address ==
                                        Address.nullAddress
                                    ? Center(
                                        child: Text(
                                          S.of(context).chooseAddress,
                                          style: AppTextStyle.regularText,
                                        ),
                                      )
                                    : Text(
                                        state.salesInvoice!.address!
                                            .firstLine(),
                                        style: AppTextStyle.boldText,
                                      ),
                                if (state.salesInvoice?.address !=
                                    Address.nullAddress)
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
                        Text(
                          S.of(context).totalCost,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (state.salesInvoice != null &&
                                state.salesInvoice!.getTotalBasedPrice() >
                                    state.salesInvoice!.totalPrice)
                              Text(
                                '\$${state.salesInvoice!.getTotalBasedPrice().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            Text(
                              '\$${state.salesInvoice?.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
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
                          if (state.salesInvoice?.address ==
                              Address.nullAddress) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => InformationDialog(
                                title: S.of(context).chooseAddress,
                                content: S.of(context).addShippingAddress,
                                dialogName: DialogName.failure,
                                buttonText: S.of(context).ok,
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderScreen.newInstance(
                                        orderOption: OrderOption.toShip,
                                      ),
                                    ),
                                        (route) => false,
                                  );
                                },
                              ),
                            );
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
                        child: Text(
                          S.of(context).placeOrder,
                          style: const TextStyle(
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
      case CategoryEnum.drive:
        return Icons.storage;
      case CategoryEnum.mainboard:
        return Icons.dashboard;
    }
  }
}