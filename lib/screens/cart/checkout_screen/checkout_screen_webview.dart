import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/address_related/address.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_image.dart';
import 'package:gizmoglobe_client/screens/cart/choose_address_screen/choose_address_screen_view.dart';
import 'package:gizmoglobe_client/screens/cart/choose_address_screen/choose_address_popup_webview.dart';
import 'package:gizmoglobe_client/screens/cart/choose_voucher_screen/choose_voucher_screen_view.dart';
import 'package:gizmoglobe_client/screens/cart/choose_voucher_screen/choose_voucher_popup_webview.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_view.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import '../../../enums/invoice_related/payment_method.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/order_option_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../sepay_payment_screen/sepay_payment_screen.dart';
import '../sepay_payment_screen/sepay_payment_modal_webview.dart';
import 'checkout_screen_cubit.dart';
import 'checkout_screen_state.dart';

class CheckoutScreenWebView extends StatefulWidget {
  final List<Map<Product, int>>? cartItems;
  final String? salesInvoiceID;

  const CheckoutScreenWebView({
    super.key,
    required List<Map<Product, int>> this.cartItems,
  }) : salesInvoiceID = null;

  const CheckoutScreenWebView.fromInvoiceId({
    super.key,
    required String this.salesInvoiceID,
  }) : cartItems = null;

  static Widget newInstance({required List<Map<Product, int>> cartItems}) =>
      BlocProvider(
        create: (context) => CheckoutScreenCubit(),
        child: CheckoutScreenWebView(cartItems: cartItems),
      );

  static Widget newInstanceFromInvoiceId({required String salesInvoiceID}) =>
      BlocProvider(
        create: (context) => CheckoutScreenCubit(),
        child:
            CheckoutScreenWebView.fromInvoiceId(salesInvoiceID: salesInvoiceID),
      );

  @override
  State<CheckoutScreenWebView> createState() => _CheckoutScreenWebViewState();
}

class _CheckoutScreenWebViewState extends State<CheckoutScreenWebView> {
  CheckoutScreenCubit get cubit => context.read<CheckoutScreenCubit>();
  bool _hasNavigatedToSePay = false;
  bool _hasShownSuccessDialog = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const WebHeader(),
            // Breadcrumbs
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          );
                        },
                        child: Text(
                          S.of(context).homeTab,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('/',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          )),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/cart');
                        },
                        child: Text(
                          S.of(context).cart,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('/',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          )),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).checkoutTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<CheckoutScreenCubit, CheckoutScreenState>(
                listener: (context, state) {
                  // Handle SePay payment navigation
                  if (state.selectedPaymentMethod == PaymentMethod.sepay &&
                      state.processState == ProcessState.idle &&
                      !_hasNavigatedToSePay &&
                      state.salesInvoice != null &&
                      state.salesInvoice!.salesInvoiceID != null &&
                      state.salesInvoice!.salesInvoiceID!.isNotEmpty) {
                    _hasNavigatedToSePay = true;
                    // On web: show compact modal; otherwise push full screen
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      bool? paymentSuccess;
                      if (kIsWeb) {
                        paymentSuccess = await showSePayPaymentModal(
                          context,
                          orderId: state.salesInvoice!.salesInvoiceID!,
                          amount: state.salesInvoice!.totalPrice,
                          customerName: state.salesInvoice!.customerName,
                          description:
                              'Order ${state.salesInvoice!.salesInvoiceID}',
                        );
                      } else {
                        paymentSuccess = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SePayPaymentScreen.newInstance(
                              orderId: state.salesInvoice!.salesInvoiceID!,
                              amount: state.salesInvoice!.totalPrice,
                              customerName: state.salesInvoice!.customerName,
                              description:
                                  'Order ${state.salesInvoice!.salesInvoiceID}',
                            ),
                          ),
                        );
                      }
                      _hasNavigatedToSePay = false;
                      if (paymentSuccess == true) {
                        final currentState = cubit.state;
                        if (currentState.salesInvoice != null &&
                            currentState.salesInvoice!.salesInvoiceID != null) {
                          cubit.completeSePayPayment(
                              currentState.salesInvoice!.salesInvoiceID!);
                        }
                      } else {
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/cart',
                            (route) => false,
                          );
                        }
                      }
                    });
                  } else if (state.processState == ProcessState.success &&
                      !_hasShownSuccessDialog) {
                    _hasShownSuccessDialog = true;
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

                    if ((state.message
                            .toLowerCase()
                            .contains('payment failed') ||
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

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      final isTablet = constraints.maxWidth >= 768 &&
                          constraints.maxWidth < 1024;

                      if (isMobile) {
                        return _buildMobileLayout(state);
                      } else {
                        return _buildDesktopLayout(state, isTablet);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(CheckoutScreenState state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items Section
                _buildOrderItemsSection(state),
                const SizedBox(height: 24),
                // Voucher Section
                _buildVoucherSection(state),
                const SizedBox(height: 24),
                // Address Section
                _buildAddressSection(state),
                const SizedBox(height: 24),
                // Payment Method Section
                _buildPaymentMethodSection(state),
                const SizedBox(height: 24),
                // Summary Section (scrollable on mobile)
                _buildSummarySection(state, isMobile: true),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(CheckoutScreenState state, bool isTablet) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 80,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Order Items, Voucher, Address
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderItemsSection(state),
                      const SizedBox(height: 24),
                      _buildVoucherSection(state),
                      const SizedBox(height: 24),
                      _buildAddressSection(state),
                      const SizedBox(height: 24),
                      _buildPaymentMethodSection(state),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column - Summary
                Expanded(
                  flex: 1,
                  child: _buildSummarySection(state, isMobile: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(CheckoutScreenState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).cart,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (state.salesInvoice?.details.isEmpty ?? true)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  S.of(context).emptyCart,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            ...state.salesInvoice!.details.map((detail) {
              final product = detail.product;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image/Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product.productID != null
                          ? FutureBuilder<ProductImage?>(
                              future: Firebase()
                                  .getProductPrimaryImage(product.productID!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    !snapshot.hasData ||
                                    snapshot.data == null ||
                                    snapshot.data!.url.isEmpty) {
                                  return Center(
                                    child: Icon(
                                      _getCategoryIcon(product.category),
                                      size: 36,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    snapshot.data!.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          _getCategoryIcon(product.category),
                                          size: 36,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                _getCategoryIcon(product.category),
                                size: 36,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (product.discount > 0) ...[
                                Text(
                                  Helper.toCurrencyFormat(product.price),
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                Helper.toCurrencyFormat(detail.sellingPrice),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${detail.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(CheckoutScreenState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).voucher,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final voucher = kIsWeb
                  ? await showChooseVoucherModal(
                      context,
                      totalAmount: state.salesInvoice!.getTotalBasedPrice(),
                      currentVoucher: state.salesInvoice!.voucher,
                    )
                  : await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChooseVoucherScreen.newInstance(
                          totalAmount: state.salesInvoice!.getTotalBasedPrice(),
                          currentVoucher: state.salesInvoice!.voucher,
                        ),
                      ),
                    );

              if (voucher != null) {
                await cubit.updateVoucher(voucher);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: state.salesInvoice?.voucher == null
                        ? Text(
                            S.of(context).addVoucher,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.salesInvoice!.voucher!.voucherName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (state.salesInvoice!.voucherDiscount > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '- ${Helper.toCurrencyFormat(state.salesInvoice!.voucherDiscount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildAddressSection(CheckoutScreenState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).shippingAddress,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final currentAddress =
                  state.salesInvoice?.address ?? Address.nullAddress;
              Address address = kIsWeb
                  ? await showChooseAddressModal(
                        context,
                        currentAddress: currentAddress,
                      ) ??
                      Address.nullAddress
                  : await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChooseAddressScreen.newInstance(
                          address: currentAddress,
                        ),
                      ),
                    );

              if (address != Address.nullAddress) {
                await cubit.updateAddress(address);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: (state.salesInvoice?.address == null ||
                            state.salesInvoice?.address == Address.nullAddress)
                        ? Text(
                            S.of(context).chooseAddress,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.salesInvoice!.address!.firstLine(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.salesInvoice!.address!.secondLine(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
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
    );
  }

  Widget _buildSummarySection(CheckoutScreenState state,
      {required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: isMobile
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).orderSummary,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).subtotal,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              Text(
                Helper.toCurrencyFormat(
                  state.salesInvoice?.getTotalBasedPrice() ?? 0,
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Voucher Discount
          if (state.salesInvoice?.voucherDiscount != null &&
              state.salesInvoice!.voucherDiscount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${S.of(context).voucher} ${S.of(context).discount}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '- ${Helper.toCurrencyFormat(state.salesInvoice!.voucherDiscount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          // Total
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (state.salesInvoice != null &&
                      state.salesInvoice!.getTotalBasedPrice() >
                          state.salesInvoice!.totalPrice)
                    Text(
                      Helper.toCurrencyFormat(
                        state.salesInvoice!.getTotalBasedPrice(),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          _buildPaymentMethodSummary(state),
          const SizedBox(height: 24),
          // Place Order Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (state.salesInvoice?.address == null ||
                    state.salesInvoice?.address == Address.nullAddress) {
                  SnackbarService.showWarning(
                    context,
                    title: S.of(context).chooseAddress,
                    message: S.of(context).addShippingAddress,
                  );
                  return;
                }
                await cubit.checkout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                S.of(context).placeOrder,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(CheckoutScreenState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).paymentMethod,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<PaymentMethod>(
            groupValue: state.selectedPaymentMethod,
            onChanged: (value) {
              if (value != null) {
                cubit.updatePaymentMethod(value);
              }
            },
            child: Column(
              children: [
                _buildPaymentMethodOption(
                  selectedMethod: state.selectedPaymentMethod,
                  method: PaymentMethod.cod,
                  title: S.of(context).cashOnDelivery,
                  description: S.of(context).payWhenYouReceive,
                  icon: Icons.money,
                  isSelected: state.selectedPaymentMethod == PaymentMethod.cod,
                  onTap: () => cubit.updatePaymentMethod(PaymentMethod.cod),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodOption(
                  selectedMethod: state.selectedPaymentMethod,
                  method: PaymentMethod.sepay,
                  title: S.of(context).sepay,
                  description: S.of(context).sepayDescription,
                  icon: Icons.account_balance,
                  isSelected:
                      state.selectedPaymentMethod == PaymentMethod.sepay,
                  onTap: () => cubit.updatePaymentMethod(PaymentMethod.sepay),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodOption(
                  selectedMethod: state.selectedPaymentMethod,
                  method: PaymentMethod.stripe,
                  title: S.of(context).stripe,
                  description: S.of(context).stripeDescription,
                  icon: Icons.credit_card,
                  isSelected:
                      state.selectedPaymentMethod == PaymentMethod.stripe,
                  onTap: () => cubit.updatePaymentMethod(PaymentMethod.stripe),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethod selectedMethod,
    required PaymentMethod method,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PaymentMethod>(
              value: method,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isDisabled
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4)
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
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

  Widget _buildPaymentMethodSummary(CheckoutScreenState state) {
    String title;
    String description;
    IconData icon;

    switch (state.selectedPaymentMethod) {
      case PaymentMethod.cod:
        title = S.of(context).cashOnDelivery;
        description = S.of(context).payWhenYouReceive;
        icon = Icons.money;
        break;
      case PaymentMethod.sepay:
        title = S.of(context).sepay;
        description = S.of(context).sepayDescription;
        icon = Icons.account_balance;
        break;
      case PaymentMethod.stripe:
        title = S.of(context).stripe;
        description = S.of(context).stripeDescription;
        icon = Icons.credit_card;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
