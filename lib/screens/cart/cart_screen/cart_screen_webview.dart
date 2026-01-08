import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/cart_item.dart';
import 'package:gizmoglobe_client/objects/product_related/product_image.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_screen_view.dart';
import 'package:gizmoglobe_client/screens/cart/checkout_screen/checkout_screen_webview.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_view.dart';

import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/widgets/dialog/confirmation_dialog.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../functions/helper.dart';
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
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _checkGuestUser();
  }

  @override
  void dispose() {
    // Dispose all quantity controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
  }

  TextEditingController _getQuantityController(CartItem item) {
    final productID = item.product.productID ?? '';
    if (!_quantityControllers.containsKey(productID)) {
      _quantityControllers[productID] = TextEditingController(
        text: item.quantity.toString(),
      );
    }
    return _quantityControllers[productID]!;
  }

  void _handleQuantityInput(CartItem item, String value) {
    final parsedQuantity = int.tryParse(value);
    if (parsedQuantity != null && parsedQuantity >= 1) {
      cubit.updateQuantity(item, parsedQuantity);
    } else {
      // Revert to current valid quantity if input is invalid
      final controller = _getQuantityController(item);
      if (controller.text != item.quantity.toString()) {
        controller.text = item.quantity.toString();
      }
    }
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
            child: BlocConsumer<CartScreenCubit, CartScreenState>(
              listener: (context, state) {
                // Sync quantity controllers with state after frame is built
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  final currentProductIDs = state.items
                      .map((item) => item.product.productID ?? '')
                      .where((id) => id.isNotEmpty)
                      .toSet();

                  // Remove controllers for items no longer in cart
                  final controllersToRemove = _quantityControllers.keys
                      .where((id) => !currentProductIDs.contains(id))
                      .toList();
                  for (var id in controllersToRemove) {
                    _quantityControllers[id]?.dispose();
                    _quantityControllers.remove(id);
                  }

                  // Sync existing controllers and create new ones for new items
                  for (var item in state.items) {
                    final productID = item.product.productID ?? '';
                    if (productID.isEmpty) continue;

                    if (_quantityControllers.containsKey(productID)) {
                      final controller = _quantityControllers[productID]!;
                      // Only update if the parsed value doesn't match state
                      // This prevents overwriting user input during editing
                      final parsedValue = int.tryParse(controller.text);
                      if (controller.text.isEmpty ||
                          parsedValue == null ||
                          parsedValue != item.quantity) {
                        controller.text = item.quantity.toString();
                      }
                    } else {
                      _quantityControllers[productID] = TextEditingController(
                        text: item.quantity.toString(),
                      );
                    }
                  }
                });

                // Handle sign-in modal for guest users
                if (state.processState == ProcessState.failure &&
                    state.error == 'User not logged in' &&
                    kIsWeb) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
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
              },
              builder: (context, state) {
                if (state.processState == ProcessState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.processState == ProcessState.failure) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          // Mobile layout: Column with order summary on top
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary first on mobile
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: BlocBuilder<CartScreenCubit, CartScreenState>(
                    builder: (context, currentState) {
                      return _buildOrderSummary(currentState);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Cart Items List
                ...state.items
                    .map((item) => _buildCartItem(item, state, isMobile: true)),
              ],
            ),
          );
        }

        // Desktop layout: Row with sidebar
        return Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Cart Items List - Main Content
              Expanded(
                flex: 2,
                child: _buildCartItemsList(state, isMobile: false),
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
                child: BlocBuilder<CartScreenCubit, CartScreenState>(
                  builder: (context, currentState) {
                    return _buildOrderSummary(currentState);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemsList(CartScreenState state, {required bool isMobile}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items.elementAt(index);
        return _buildCartItem(item, state, isMobile: isMobile);
      },
    );
  }

  Widget _buildCartItem(CartItem item, CartScreenState state,
      {required bool isMobile}) {
    // Check selection by productID for reliability using the state passed in
    final productID = item.product.productID;
    final isSelected = state.selectedItems.any(
      (selectedItem) => selectedItem.product.productID == productID,
    );
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
        child: InkWell(
          onTap: () {
            final productId = product.productID;
            if (kIsWeb && productId != null) {
              Navigator.of(context).pushNamed('/products/$productId');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen.newInstance(product),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: isMobile
                ? _buildMobileCartItem(
                    item,
                    isSelected,
                    product,
                    originalPrice.toDouble(),
                    discount.toDouble(),
                    finalPrice.toDouble())
                : _buildDesktopCartItem(
                    item,
                    isSelected,
                    product,
                    originalPrice.toDouble(),
                    discount.toDouble(),
                    finalPrice.toDouble()),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCartItem(CartItem item, bool isSelected, dynamic product,
      double originalPrice, double discount, double finalPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Checkbox + Image + Name
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  cubit.toggleItemSelection(item);
                },
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Theme.of(context).colorScheme.surface,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            // Product Image - smaller on mobile
            _buildProductImage(product, 60, 28),
            const SizedBox(width: 12),
            // Product Name
            Expanded(
              child: Text(
                product.productName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Price row
        Row(
          children: [
            const SizedBox(width: 32), // Align with product name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${(discount).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    Helper.toCurrencyFormat(finalPrice),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row: Subtotal + Quantity + Delete
        Row(
          children: [
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                '${S.of(context).subtotal}: ${Helper.toCurrencyFormat(item.subTotal())}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Compact quantity controls
            GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: item.quantity > 1
                          ? () => cubit.updateQuantity(item, item.quantity - 1)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: item.quantity > 1
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        controller: _getQuantityController(item),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (value) =>
                            _handleQuantityInput(item, value),
                        onTapOutside: (event) {
                          final value = _getQuantityController(item).text;
                          _handleQuantityInput(item, value);
                        },
                      ),
                    ),
                    InkWell(
                      onTap: item.quantity < item.product.stock
                          ? () => cubit.updateQuantity(item, item.quantity + 1)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: item.quantity < item.product.stock
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delete button
            InkWell(
              onTap: () => _showDeleteDialog(item),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: S.of(context).removeItem,
        content: S.of(context).removeItemConfirmation,
        confirmText: S.of(context).remove,
        cancelText: S.of(context).cancel,
        onConfirm: () {
          Navigator.pop(context);
          cubit.removeFromCart(item);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildDesktopCartItem(CartItem item, bool isSelected, dynamic product,
      double originalPrice, double discount, double finalPrice) {
    return Row(
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        // Product Image
        _buildProductImage(product, 100, 40),
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
                '${S.of(context).subtotal}: ${(Helper.toCurrencyFormat(item.subTotal()))}',
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
        GestureDetector(
          onTap: () {}, // Stop event propagation
          child: Column(
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
                              cubit.updateQuantity(item, item.quantity - 1);
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
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _getQuantityController(item),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (value) =>
                            _handleQuantityInput(item, value),
                        onTapOutside: (event) {
                          final value = _getQuantityController(item).text;
                          _handleQuantityInput(item, value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: item.quantity < item.product.stock
                          ? () {
                              cubit.updateQuantity(item, item.quantity + 1);
                            }
                          : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: item.quantity < item.product.stock
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 24),
                onPressed: () => _showDeleteDialog(item),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                tooltip: S.of(context).removeItem,
              ),
            ],
          ),
        ),
      ],
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
              S.of(context).orderSummary,
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
                  S.of(context).itemsCount(state.selectedCount),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                Text(
                  Helper.toCurrencyFormat(state.selectedItemsTotalAmount),
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
            if (state.selectedItemsHasDiscounts && state.selectedCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).originalPrice,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    Helper.toCurrencyFormat(
                        state.selectedItemsTotalBeforeDiscount),
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
                    S.of(context).discount,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-${Helper.toCurrencyFormat(state.selectedItemsTotalBeforeDiscount - state.selectedItemsTotalAmount)}',
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
                  S.of(context).shippingFee,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                Text(
                  S.of(context).free,
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
                  S.of(context).totalCost,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  Helper.toCurrencyFormat(state.selectedItemsTotalAmount),
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
                        // Navigate to checkout with cart items
                        // Invoice will be created in Firebase when checkout screen loads
                        final cartItems =
                            cubit.convertItemsToProductQuantityList();
                        if (kIsWeb) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CheckoutScreenWebView.newInstance(
                                cartItems: cartItems,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen.newInstance(
                                cartItems: cartItems,
                              ),
                            ),
                          );
                        }
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
            // Clear Cart / Delete Selected Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: state.items.isNotEmpty
                    ? () {
                        final hasSelection = state.selectedCount > 0;
                        final dialogTitle = hasSelection
                            ? S.of(context).removeItem
                            : S.of(context).clearCart;
                        final dialogContent = hasSelection
                            ? '${S.of(context).removeItemConfirmation} (${state.selectedCount})'
                            : S.of(context).clearCartConfirmation;
                        final confirmText = hasSelection
                            ? S.of(context).remove
                            : S.of(context).clearAll;

                        showDialog(
                          context: context,
                          builder: (context) => ConfirmationDialog(
                            title: dialogTitle,
                            content: dialogContent,
                            confirmText: confirmText,
                            cancelText: S.of(context).cancel,
                            onConfirm: () {
                              Navigator.pop(context);
                              if (hasSelection) {
                                cubit.deleteSelectedItems();
                              } else {
                                cubit.clearCart();
                              }
                            },
                            onCancel: () => Navigator.pop(context),
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
                  state.selectedCount > 0
                      ? '${S.of(context).remove} (${state.selectedCount})'
                      : S.of(context).clearCart,
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

  Widget _buildProductImage(dynamic product, double size, double iconSize) {
    final productId = product.productID;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: productId != null
            ? FutureBuilder<ProductImage?>(
                future: Firebase().getProductPrimaryImage(productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: iconSize,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.url.isEmpty) {
                    return Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: iconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }

                  return CachedNetworkImage(
                    imageUrl: snapshot.data!.url,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: iconSize,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: iconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  _getCategoryIcon(product.category),
                  size: iconSize,
                  color: Theme.of(context).colorScheme.primary,
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
        return Icons.devices_other;
    }
  }
}
