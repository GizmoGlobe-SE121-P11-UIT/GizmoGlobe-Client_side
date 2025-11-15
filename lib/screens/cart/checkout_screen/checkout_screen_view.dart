import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';

import '../../../enums/invoice_related/payment_method.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/order_option_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../generated/l10n.dart';
import '../../../objects/address_related/address.dart';
import '../../../objects/product_related/product.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/general/gradient_text.dart';
import '../../user/order_screen/order_screen_view.dart';
import '../choose_address_screen/choose_address_screen_view.dart';
import '../choose_voucher_screen/choose_voucher_screen_view.dart';
import '../sepay_payment_screen/sepay_payment_screen.dart';
import 'checkout_screen_cubit.dart';
import 'checkout_screen_state.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<Product, int>>? cartItems;
  final String? salesInvoiceID;

  const CheckoutScreen({
    super.key,
    required List<Map<Product, int>> cartItems,
  })  : cartItems = cartItems,
        salesInvoiceID = null;

  const CheckoutScreen.fromInvoiceId({
    super.key,
    required String salesInvoiceID,
  })  : cartItems = null,
        salesInvoiceID = salesInvoiceID;

  static Widget newInstance({required List<Map<Product, int>> cartItems}) =>
      BlocProvider(
        create: (context) => CheckoutScreenCubit(),
        child: CheckoutScreen(cartItems: cartItems),
      );

  static Widget newInstanceFromInvoiceId({required String salesInvoiceID}) =>
      BlocProvider(
        create: (context) => CheckoutScreenCubit(),
        child: CheckoutScreen.fromInvoiceId(salesInvoiceID: salesInvoiceID),
      );

  @override
  State<CheckoutScreen> createState() => _CheckoutScreen();
}

class _CheckoutScreen extends State<CheckoutScreen> {
  CheckoutScreenCubit get cubit => context.read<CheckoutScreenCubit>();
  bool _hasNavigatedToSePay = false;

  @override
  void initState() {
    super.initState();
    if (widget.salesInvoiceID != null) {
      cubit.initializeFromInvoiceId(widget.salesInvoiceID!);
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      // Create invoice in memory only (not in Firebase)
      // Invoice will be saved to Firebase only when user places the order
      cubit.initialize(widget.cartItems!);
    }
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
          fillColor: Colors.transparent,
        ),
        title: GradientText(text: S.of(context).checkoutTitle),
      ),
      body: BlocConsumer<CheckoutScreenCubit, CheckoutScreenState>(
        listener: (context, state) {
          // Handle SePay payment navigation
          if (state.selectedPaymentMethod == PaymentMethod.sepay &&
              state.processState == ProcessState.idle &&
              !_hasNavigatedToSePay &&
              state.salesInvoice != null &&
              state.salesInvoice!.salesInvoiceID != null &&
              state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
            _hasNavigatedToSePay = true;
            // Navigate to SePay payment screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SePayPaymentScreen.newInstance(
                    orderId: state.salesInvoice!.salesInvoiceID!,
                    amount: state.salesInvoice!.totalPrice,
                    customerName: state.salesInvoice!.customerName,
                    description: 'Order ${state.salesInvoice!.salesInvoiceID}',
                  ),
                ),
              ).then((paymentSuccess) {
                _hasNavigatedToSePay = false;
                // Payment screen returned - check if payment was successful
                if (paymentSuccess == true) {
                  // Complete the payment in cubit
                  final currentState = cubit.state;
                  if (currentState.salesInvoice != null &&
                      currentState.salesInvoice!.salesInvoiceID != null) {
                    cubit.completeSePayPayment(
                        currentState.salesInvoice!.salesInvoiceID!);
                  }
                }
              });
            });
          } else if (state.processState == ProcessState.success) {
            // Only show success if we have a valid invoice with address
            // This prevents showing success when address validation fails
            if (state.salesInvoice != null &&
                state.salesInvoice!.address != null &&
                state.salesInvoice!.address != Address.nullAddress) {
              if (context.mounted) {
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
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderScreen.newInstance(
                              orderOption: OrderOption.toShip,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                );
              }
            }
          } else if (state.processState == ProcessState.failure) {
            String errorMessage = S.of(context).errorCheckout;

            // Handle specific error types with user-friendly messages
            final messageLower = state.message.toLowerCase();
            if (messageLower.contains('payment failed') ||
                messageLower.contains('stripe')) {
              errorMessage = S.of(context).paymentCancelled;
            } else if (messageLower.contains('sepay') ||
                messageLower.contains('virtual account') ||
                messageLower.contains('bank account')) {
              // SePay specific errors
              if (messageLower.contains('no bank accounts') ||
                  messageLower.contains('cannot connect')) {
                errorMessage =
                    'SePay service is currently unavailable. Please try again later or use a different payment method.';
              } else {
                errorMessage =
                    'SePay payment failed. Please try again or use a different payment method.';
              }
            } else if (messageLower.contains('bad state') ||
                messageLower.contains('no element')) {
              // Technical errors - show generic message
              errorMessage =
                  'Payment processing error. Please try again or contact support.';
            }

            if (context.mounted) {
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
          }
        },
        builder: (context, state) {
          if (state.processState == ProcessState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.salesInvoice?.details.length ?? 0,
                        itemBuilder: (context, index) {
                          if (state.salesInvoice == null ||
                              index >= (state.salesInvoice!.details.length)) {
                            return const SizedBox.shrink();
                          }
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: AppTextStyle.boldText,
                                      ),
                                      const SizedBox(height: 4),
                                      if (product.discount > 0) ...[
                                        Text(
                                          Helper.toCurrencyFormat(
                                              product.price),
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        Helper.toCurrencyFormat(
                                            detail.sellingPrice),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
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
                                      constraints:
                                          const BoxConstraints(minWidth: 16),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).voucher,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),
                              GestureDetector(
                                onTap: state.salesInvoice == null
                                    ? null
                                    : () async {
                                        final voucher = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChooseVoucherScreen.newInstance(
                                              totalAmount: state.salesInvoice!
                                                  .getTotalBasedPrice(),
                                              currentVoucher:
                                                  state.salesInvoice!.voucher,
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
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: state.salesInvoice?.voucher ==
                                                null
                                            ? Text(
                                                S.of(context).addVoucher,
                                                style: AppTextStyle.regularText,
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    state.salesInvoice!.voucher!
                                                        .voucherName,
                                                    style:
                                                        AppTextStyle.boldText,
                                                  ),
                                                  if (state.salesInvoice!
                                                          .voucherDiscount >
                                                      0)
                                                    Text(
                                                      '- ${Helper.toCurrencyFormat(state.salesInvoice!.voucherDiscount)}',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),
                              GestureDetector(
                                onTap: state.salesInvoice == null
                                    ? null
                                    : () async {
                                        final address =
                                            await Navigator.push<Address>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ChooseAddressScreen
                                                      .newInstance(
                                                          address: state
                                                                  .salesInvoice!
                                                                  .address ??
                                                              Address
                                                                  .nullAddress)),
                                        );

                                        if (address != null &&
                                            address != Address.nullAddress) {
                                          cubit.updateAddress(address);
                                        }
                                      },
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        (state.salesInvoice == null ||
                                                state.salesInvoice?.address ==
                                                    null ||
                                                state.salesInvoice?.address ==
                                                    Address.nullAddress)
                                            ? Center(
                                                child: Text(
                                                  S.of(context).chooseAddress,
                                                  style:
                                                      AppTextStyle.regularText,
                                                ),
                                              )
                                            : Text(
                                                state.salesInvoice!.address!
                                                    .firstLine(),
                                                style: AppTextStyle.boldText,
                                              ),
                                        if (state.salesInvoice != null &&
                                            state.salesInvoice!.address !=
                                                null &&
                                            state.salesInvoice!.address !=
                                                Address.nullAddress)
                                          Text(
                                            state.salesInvoice!.address!
                                                .secondLine(),
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
                      const SizedBox(height: 16),
                      // Payment Method Selection - Tappable to open bottom sheet
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () =>
                                _showPaymentMethodBottomSheet(context, state),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          S.of(context).paymentMethod,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildPaymentMethodPreview(state),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Section - Pinned at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                                  Helper.toCurrencyFormat(
                                      state.salesInvoice!.getTotalBasedPrice()),
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              Text(
                                Helper.toCurrencyFormat(
                                    state.salesInvoice?.totalPrice ?? 0),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
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
                            // Validate address before proceeding
                            if (state.salesInvoice == null ||
                                state.salesInvoice?.address == null ||
                                state.salesInvoice?.address ==
                                    Address.nullAddress) {
                              if (context.mounted) {
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
                                    },
                                  ),
                                );
                              }
                              return; // Prevent checkout if address is missing
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodOptionMobile({
    required PaymentMethod selectedMethod,
    required PaymentMethod method,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PaymentMethod>(
              value: method,
              groupValue: selectedMethod,
              onChanged: isDisabled ? null : (_) => onTap(),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isDisabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.boldText.copyWith(
                      color: isDisabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyle.regularText.copyWith(
                      color: isDisabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodPreview(CheckoutScreenState state) {
    String paymentMethodText;
    IconData paymentMethodIcon;

    switch (state.selectedPaymentMethod) {
      case PaymentMethod.cod:
        paymentMethodText = S.of(context).cashOnDelivery;
        paymentMethodIcon = Icons.money;
        break;
      case PaymentMethod.sepay:
        paymentMethodText = S.of(context).sepay;
        paymentMethodIcon = Icons.account_balance;
        break;
      case PaymentMethod.stripe:
        paymentMethodText = S.of(context).stripe;
        paymentMethodIcon = Icons.credit_card;
        break;
    }

    return Row(
      children: [
        Icon(
          paymentMethodIcon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          paymentMethodText,
          style: AppTextStyle.boldText.copyWith(fontSize: 16),
        ),
      ],
    );
  }

  void _showPaymentMethodBottomSheet(
      BuildContext context, CheckoutScreenState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) =>
          BlocBuilder<CheckoutScreenCubit, CheckoutScreenState>(
        bloc: cubit,
        builder: (context, currentState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      S.of(context).paymentMethod,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Payment method options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPaymentMethodOptionMobile(
                      selectedMethod: currentState.selectedPaymentMethod,
                      method: PaymentMethod.cod,
                      title: S.of(context).cashOnDelivery,
                      description: S.of(context).payWhenYouReceive,
                      icon: Icons.money,
                      isSelected: currentState.selectedPaymentMethod ==
                          PaymentMethod.cod,
                      onTap: () {
                        cubit.updatePaymentMethod(PaymentMethod.cod);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodOptionMobile(
                      selectedMethod: currentState.selectedPaymentMethod,
                      method: PaymentMethod.sepay,
                      title: S.of(context).sepay,
                      description: S.of(context).sepayDescription,
                      icon: Icons.account_balance,
                      isSelected: currentState.selectedPaymentMethod ==
                          PaymentMethod.sepay,
                      onTap: () {
                        cubit.updatePaymentMethod(PaymentMethod.sepay);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodOptionMobile(
                      selectedMethod: currentState.selectedPaymentMethod,
                      method: PaymentMethod.stripe,
                      title: S.of(context).stripe,
                      description: S.of(context).stripeDescription,
                      icon: Icons.credit_card,
                      isSelected: currentState.selectedPaymentMethod ==
                          PaymentMethod.stripe,
                      onTap: () {
                        cubit.updatePaymentMethod(PaymentMethod.stripe);
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      default:
        return Icons.devices;
    }
  }
}
