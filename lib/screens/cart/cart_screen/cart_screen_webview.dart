import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/cart_item.dart';
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_screen_view.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../functions/helper.dart';
import '../../../objects/product_related/product.dart';
import 'cart_screen_cubit.dart';
import 'cart_screen_state.dart';

class CartScreenWebView extends StatefulWidget {
  const CartScreenWebView({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => CartScreenCubit(),
        child: const CartScreenWebView(),
      );

  static Widget withCubit(CartScreenCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const CartScreenWebView(),
      );

  @override
  State<CartScreenWebView> createState() => _CartScreenWebViewState();
}

class _CartScreenWebViewState extends State<CartScreenWebView> {
  CartScreenCubit get cubit => context.read<CartScreenCubit>();
  final WebGuestService _webGuestService = WebGuestService();

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
  }

  Future<void> _checkGuestUser() async {
    if (kIsWeb) {
      final isGuest = await _webGuestService.isCurrentUserGuest();
      if (isGuest) {
        // Show snackbar and sign-in modal for guest users
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final overlayState = Navigator.of(context).overlay!;
          SnackbarService.showGuestRestrictionAboveOverlay(
            overlayState,
            context: context,
            actionType: 'cart',
          );
          final signInCubit = SignInCubit();
          await showSignInModalWithCubit(context, signInCubit);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Web Header (only on web)
          if (kIsWeb) const WebHeader(),
          // Main Content
          Expanded(
            child: BlocBuilder<CartScreenCubit, CartScreenState>(
              builder: (context, state) {
                if (state.processState == ProcessState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.processState == ProcessState.failure) {
                  // If it's a "User not logged in" error, show sign-in modal
                  if (state.error == 'User not logged in' && kIsWeb) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final overlayState = Navigator.of(context).overlay!;
                      SnackbarService.showGuestRestrictionAboveOverlay(
                        overlayState,
                        context: context,
                        actionType: 'cart',
                      );
                      final signInCubit = SignInCubit();
                      await showSignInModalWithCubit(context, signInCubit);
                    });
                  }
                  return Center(
                      child:
                          Text(state.error ?? S.of(context).errorLoadingCart));
                }

                if (state.items.isEmpty) {
                  return _buildEmptyCart();
                }

                return _buildWebLayout(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).emptyCart,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).emptyCartDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/products',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                S.of(context).browseProducts,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(CartScreenState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Cart Items List - Main Content
          Expanded(
            flex: 2,
            child: _buildCartItemsList(state),
          ),
          // Order Summary Sidebar
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: _buildOrderSummary(state),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(CartScreenState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items.elementAt(index);
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    final isSelected = context
        .read<CartScreenCubit>()
        .state
        .selectedItems
        .contains(item);
    final product = item.product;
    final originalPrice = product.price;
    final discount = product.discount;
    final finalPrice = product.discountedPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  cubit.toggleItemSelection(item);
                },
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              // Product Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(product.category),
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (discount > 0) ...[
                      Row(
                        children: [
                          Text(
                            Helper.toCurrencyFormat(originalPrice),
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${(discount).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      Helper.toCurrencyFormat(finalPrice),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subtotal: ${(Helper.toCurrencyFormat(item.subTotal()))}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity Controls
              Column(
                children: [
                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: (item.quantity) > 1
                              ? () {
                                  cubit.updateQuantity(
                                    item, item.quantity - 1
                                  );
                                }
                              : null,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: item.quantity > 1
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 40),
                          alignment: Alignment.center,
                          child: Text(
                            (item.quantity).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            cubit.updateQuantity(
                              item, item.quantity + 1
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 24),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          title: Text(
                            S.of(context).removeItem,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          content: Text(
                            S.of(context).removeItemConfirmation,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(S.of(context).cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                cubit.removeFromCart(item);
                              },
                              child: Text(
                                S.of(context).remove,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartScreenState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            // Select All
            Row(
              children: [
                Checkbox(
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Theme.of(context).colorScheme.surface,
                  value: state.isAllSelected,
                  onChanged: (value) {
                    cubit.toggleSelectAll();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).selectAll,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            // Items Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${state.selectedCount})',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                Text(
                  Helper.toCurrencyFormat(state.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Discount Display
            if (state.hasDiscounts && state.selectedCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Original Price',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                  Helper.toCurrencyFormat(state.totalBeforeDiscount),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-${Helper.toCurrencyFormat(state.totalBeforeDiscount - state.totalAmount)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Shipping
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Free',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  Helper.toCurrencyFormat(state.totalAmount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.selectedCount > 0
                    ? () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen.newInstance(
                              cartItems:
                                  cubit.convertItemsToProductQuantityList(),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.selectedCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                  foregroundColor: state.selectedCount > 0
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  S.of(context).goToCheckout,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Clear Cart Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: state.items.isNotEmpty
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            title: Text(
                              'Clear Cart',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to clear all items from your cart?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(S.of(context).cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  cubit.clearCart();
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: state.items.isNotEmpty
                        ? Colors.red
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Clear Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: state.items.isNotEmpty
                        ? Colors.red
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
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
        return Icons.devices_other;
    }
  }
}
