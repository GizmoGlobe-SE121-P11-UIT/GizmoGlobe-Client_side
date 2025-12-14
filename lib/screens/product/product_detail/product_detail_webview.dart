import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/main.dart' show rootNavigatorKey;
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard_related/mainboard.dart';
import 'package:gizmoglobe_client/services/recommendation_service.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/widgets/order/rating_card.dart';
import 'package:gizmoglobe_client/widgets/product/favorites/favorites_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import '../../cart/checkout_screen/checkout_screen_webview.dart';
import '../../cart/checkout_screen/checkout_screen_view.dart';

class _AutoScrollingButtonContent extends StatefulWidget {
  final Widget child;

  const _AutoScrollingButtonContent({required this.child});

  @override
  State<_AutoScrollingButtonContent> createState() =>
      _AutoScrollingButtonContentState();

  @override
  String toStringShort() => 'AutoScrollingButtonContent';
}

class _AutoScrollingButtonContentState
    extends State<_AutoScrollingButtonContent> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartScrolling();
    });
  }

  void _checkAndStartScrolling() {
    if (!_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _checkAndStartScrolling();
      });
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0 && !_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (!_scrollController.hasClients || !_isScrolling) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      setState(() {
        _isScrolling = false;
      });
      return;
    }

    // Scroll to end
    _scrollController
        .animateTo(
      maxScroll,
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
    )
        .then((_) {
      if (!mounted || !_isScrolling) return;
      // Pause at end
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || !_isScrolling) return;
        // Scroll back to start
        _scrollController
            .animateTo(
          0,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (!mounted || !_isScrolling) return;
          // Pause at start, then repeat
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && _isScrolling) {
              _startAutoScroll();
            }
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _isScrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('auto_scrolling_content'),
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: widget.child,
    );
  }
}

class ProductDetailScreenWebView extends StatefulWidget {
  final Product product;

  const ProductDetailScreenWebView({super.key, required this.product});

  static Widget newInstance(Product product) => BlocProvider(
        create: (context) => ProductDetailCubit(product),
        child: ProductDetailScreenWebView(product: product),
      );

  @override
  State<ProductDetailScreenWebView> createState() =>
      _ProductDetailScreenWebViewState();
}

class _ProductDetailScreenWebViewState
    extends State<ProductDetailScreenWebView> {
  ProductDetailCubit get cubit => context.read<ProductDetailCubit>();
  final WebGuestService _webGuestService = WebGuestService();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // No need to manually update the hash - Navigator.pushNamed handles it
  }

  @override
  void dispose() {
    // Don't manipulate the hash on dispose - let the browser's back/forward handle it
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleBuyNow(ProductDetailState state,
      {required bool isWeb}) async {
    final productId = widget.product.productID;
    if (productId == null) return;

    final isGuest = await _webGuestService.isCurrentUserGuest();
    if (isGuest) {
      if (!mounted) return;
      SnackbarService.showGuestRestriction(context, actionType: 'cart');
      return;
    }

    final cartItem = <Product, int>{widget.product: state.quantity};
    if (!mounted) return;

    if (isWeb) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) =>
              CheckoutScreenWebView.newInstance(cartItems: [cartItem]),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => CheckoutScreen.newInstance(cartItems: [cartItem]),
        ),
      );
    }
  }

  String _getCategoryLabel(BuildContext context, CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return S.of(context).ram;
      case CategoryEnum.cpu:
        return S.of(context).cpu;
      case CategoryEnum.psu:
        return S.of(context).psu;
      case CategoryEnum.gpu:
        return S.of(context).gpu;
      case CategoryEnum.drive:
        return S.of(context).drive;
      case CategoryEnum.mainboard:
        return S.of(context).mainboard;
      default:
        return S.of(context).all;
    }
  }

  String _getCategoryUrlPath(CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return 'ram';
      case CategoryEnum.cpu:
        return 'cpu';
      case CategoryEnum.psu:
        return 'psu';
      case CategoryEnum.gpu:
        return 'gpu';
      case CategoryEnum.drive:
        return 'drive';
      case CategoryEnum.mainboard:
        return 'mainboard';
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return Icons.memory;
      case CategoryEnum.cpu:
        return Icons.developer_board;
      case CategoryEnum.psu:
        return Icons.power;
      case CategoryEnum.gpu:
        return Icons.videocam;
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
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listener: (context, state) {
        if (state.processState == ProcessState.success) {
          // Check if it's a cart addition success
          if (state.message == 'CART_ADDED') {
            SnackbarService.showCartSuccess(
              context,
              widget.product.productName,
            );
            cubit.setIdleState();
          } else {
            // Other success cases (like order placed) show dialog
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
          }
        } else if (state.processState == ProcessState.failure) {
          // Handle cart-related failures with localized messages
          if (state.message == 'CART_ERROR') {
            SnackbarService.showCartError(context);
            cubit.setIdleState();
          } else if (state.message == 'CART_LOGIN_REQUIRED') {
            SnackbarService.showGuestRestriction(
              context,
              actionType: 'cart',
            );
            cubit.setIdleState();
          } else {
            // Other failure cases show dialog
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
        }
      },
      builder: (context, state) {
        if (state.processState == ProcessState.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                const WebHeader(),
                // Breadcrumbs: Home / Sản phẩm / <Category> / <Product Name>
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              final navigator = rootNavigatorKey.currentState;
                              if (navigator != null) {
                                navigator.pushNamed('/products');
                              }
                            },
                            child: Text(
                              'Sản phẩm',
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
                              final navigator = rootNavigatorKey.currentState;
                              if (navigator != null) {
                                final categoryPath = _getCategoryUrlPath(
                                    widget.product.category);
                                if (categoryPath.isNotEmpty) {
                                  navigator
                                      .pushNamed('/products/$categoryPath');
                                } else {
                                  navigator.pushNamed('/products');
                                }
                              }
                            },
                            child: Text(
                              _getCategoryLabel(
                                  context, widget.product.category),
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
                            widget.product.productName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
                    builder: (context, state) {
                      return SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),
                                  // Main Product Section
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth >= 900) {
                                        // Desktop Layout: Image | Details Side by Side
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Product Image Section
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                children: [
                                                  _buildImageCarouselDesktop(
                                                      context, state),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                            // Product Details Section
                                            Expanded(
                                              flex: 6,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          widget.product
                                                              .productName,
                                                          style: TextStyle(
                                                            fontSize: 32,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      FloatingActionButton(
                                                        mini: true,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .surface,
                                                        onPressed: () async {
                                                          if (state.product
                                                                  .productID !=
                                                              null) {
                                                            final isGuest =
                                                                await _webGuestService
                                                                    .isCurrentUserGuest();
                                                            if (isGuest) {
                                                              SnackbarService
                                                                  .showGuestRestriction(
                                                                context,
                                                                actionType:
                                                                    'favorites',
                                                              );
                                                              return;
                                                            }
                                                            try {
                                                              final wasFavorite =
                                                                  state
                                                                      .isFavorite;
                                                              await cubit
                                                                  .toggleFavorite();
                                                              context
                                                                  .read<
                                                                      FavoritesCubit>()
                                                                  .loadFavorites();
                                                              // Show snackbar notification
                                                              final newState =
                                                                  cubit.state;
                                                              if (newState
                                                                      .isFavorite !=
                                                                  wasFavorite) {
                                                                SnackbarService
                                                                    .showFavoriteSuccess(
                                                                  context,
                                                                  newState.isFavorite
                                                                      ? 'added'
                                                                      : 'removed',
                                                                );
                                                              }
                                                            } catch (e) {
                                                              SnackbarService
                                                                  .showFavoriteError(
                                                                      context);
                                                            }
                                                          }
                                                        },
                                                        child: Icon(
                                                          state.isFavorite
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: state
                                                                  .isFavorite
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .error
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (widget.product
                                                              .discount >
                                                          0) ...[
                                                        Row(
                                                          children: [
                                                            Text(
                                                              Helper.toCurrencyFormat(
                                                                  widget.product
                                                                      .price),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleLarge
                                                                  ?.copyWith(
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough,
                                                                    color: Colors
                                                                            .grey[
                                                                        500],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                                width: 12),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .red[700],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                              ),
                                                              child: Text(
                                                                '-${widget.product.discount.toStringAsFixed(0)}%',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelMedium
                                                                    ?.copyWith(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                      ],
                                                      Text(
                                                        Helper.toCurrencyFormat(
                                                            widget.product
                                                                .discountedPrice),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 32),
                                                  ..._buildProductSpecificDetails(
                                                      context,
                                                      state.product,
                                                      state.technicalSpecs),
                                                  const SizedBox(height: 48),
                                                  // Add to Cart Section
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            24),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                              alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .dividerColor,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              S
                                                                  .of(context)
                                                                  .quantity,
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 24),
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withValues(
                                                                            alpha:
                                                                                0.6)),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surface,
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  _buildQuantityButton(
                                                                      icon: Icons
                                                                          .remove,
                                                                      onPressed:
                                                                          () =>
                                                                              cubit.decrementQuantity()),
                                                                  Container(
                                                                    width: 60,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      state
                                                                          .quantity
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .onSurface,
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              18),
                                                                    ),
                                                                  ),
                                                                  _buildQuantityButton(
                                                                      icon: Icons
                                                                          .add,
                                                                      onPressed:
                                                                          () =>
                                                                              cubit.incrementQuantity()),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 24),
                                                        Row(
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  S
                                                                      .of(context)
                                                                      .totalPrice,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withValues(
                                                                            alpha:
                                                                                0.6),
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      Helper.toCurrencyFormat(widget
                                                                              .product
                                                                              .price *
                                                                          state
                                                                              .quantity),
                                                                      style:
                                                                          TextStyle(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .onSurface
                                                                            .withValues(alpha: 0.4),
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        decoration:
                                                                            TextDecoration.lineThrough,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Text(
                                                                      Helper.toCurrencyFormat(widget
                                                                              .product
                                                                              .discountedPrice *
                                                                          state
                                                                              .quantity),
                                                                      style:
                                                                          TextStyle(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .tertiary,
                                                                        fontSize:
                                                                            28,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const Spacer(),
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                height: 56,
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    if (widget
                                                                            .product
                                                                            .productID !=
                                                                        null) {
                                                                      final isGuest =
                                                                          await _webGuestService
                                                                              .isCurrentUserGuest();
                                                                      if (isGuest) {
                                                                        SnackbarService
                                                                            .showGuestRestriction(
                                                                          context,
                                                                          actionType:
                                                                              'cart',
                                                                        );
                                                                        return;
                                                                      }
                                                                      cubit
                                                                          .addToCart(
                                                                        widget
                                                                            .product
                                                                            .productID!,
                                                                        state
                                                                            .quantity,
                                                                      );
                                                                    }
                                                                  },
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .shopping_cart_outlined,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              8),
                                                                      Expanded(
                                                                        child:
                                                                            _AutoScrollingButtonContent(
                                                                          child:
                                                                              Align(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            child:
                                                                                Text(
                                                                              S.of(context).addToCart,
                                                                              style: const TextStyle(
                                                                                fontSize: 18,
                                                                                fontWeight: FontWeight.bold,
                                                                                letterSpacing: 0.5,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                height: 56,
                                                                child:
                                                                    OutlinedButton(
                                                                  onPressed: () =>
                                                                      _handleBuyNow(
                                                                          state,
                                                                          isWeb:
                                                                              true),
                                                                  style: OutlinedButton
                                                                      .styleFrom(
                                                                    foregroundColor: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    side:
                                                                        BorderSide(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary,
                                                                    ),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      _AutoScrollingButtonContent(
                                                                    child:
                                                                        Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child:
                                                                          Text(
                                                                        S
                                                                            .of(context)
                                                                            .buyNow,
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // Mobile/Tablet Layout: Image on Top, Details Below
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildImageCarouselMobile(
                                                context, state),
                                            const SizedBox(height: 24),
                                            Text(
                                              widget.product.productName,
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (widget.product.discount >
                                                    0) ...[
                                                  Row(
                                                    children: [
                                                      Text(
                                                        Helper.toCurrencyFormat(
                                                            widget
                                                                .product.price),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color: Colors
                                                                  .grey[500],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          '-${widget.product.discount.toStringAsFixed(0)}%',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelMedium
                                                                  ?.copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                                Text(
                                                  Helper.toCurrencyFormat(widget
                                                      .product.discountedPrice),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .displaySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            ..._buildProductSpecificDetails(
                                                context,
                                                state.product,
                                                state.technicalSpecs),
                                            const SizedBox(height: 32),
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .dividerColor,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        S.of(context).quantity,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6)),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            _buildQuantityButton(
                                                                icon: Icons
                                                                    .remove,
                                                                onPressed: () =>
                                                                    cubit
                                                                        .decrementQuantity()),
                                                            Container(
                                                              width: 50,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                state.quantity
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                            ),
                                                            _buildQuantityButton(
                                                                icon: Icons.add,
                                                                onPressed: () =>
                                                                    cubit
                                                                        .incrementQuantity()),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            S
                                                                .of(context)
                                                                .totalPrice,
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Row(
                                                            children: [
                                                              if (widget.product
                                                                      .discount >
                                                                  0)
                                                                Text(
                                                                  Helper.toCurrencyFormat(widget
                                                                          .product
                                                                          .price *
                                                                      state
                                                                          .quantity),
                                                                  style:
                                                                      TextStyle(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withValues(
                                                                            alpha:
                                                                                0.4),
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .lineThrough,
                                                                  ),
                                                                ),
                                                              if (widget.product
                                                                      .discount >
                                                                  0)
                                                                const SizedBox(
                                                                    width: 8),
                                                              Text(
                                                                Helper.toCurrencyFormat(widget
                                                                        .product
                                                                        .discountedPrice *
                                                                    state
                                                                        .quantity),
                                                                style: TextStyle(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .tertiary,
                                                                    fontSize:
                                                                        24,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 24),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 56,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        if (widget.product
                                                                .productID !=
                                                            null) {
                                                          final isGuest =
                                                              await _webGuestService
                                                                  .isCurrentUserGuest();
                                                          if (isGuest) {
                                                            SnackbarService
                                                                .showGuestRestriction(
                                                              context,
                                                              actionType:
                                                                  'cart',
                                                            );
                                                            return;
                                                          }
                                                          cubit.addToCart(
                                                            widget.product
                                                                .productID!,
                                                            state.quantity,
                                                          );
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        foregroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onPrimary,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .shopping_cart_outlined,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _AutoScrollingButtonContent(
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  S
                                                                      .of(context)
                                                                      .addToCart,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    letterSpacing:
                                                                        0.5,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 56,
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          _handleBuyNow(state,
                                                              isWeb: false),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        side: BorderSide(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child:
                                                          _AutoScrollingButtonContent(
                                                        child: Align(
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            S
                                                                .of(context)
                                                                .buyNow,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 48),
                                  _buildRatingAndCommentsSection(),
                                  const SizedBox(height: 48),
                                  _buildRecommendationsSection(
                                      context, state.product),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildProductSpecificDetails(
      BuildContext context, Product product, Map<String, String> specs) {
    return specs.entries.map((entry) {
      String value = entry.value;
      // Format RAM Spec with localization if it's a Mainboard
      if (entry.key == 'RAM Spec' &&
          product.category == CategoryEnum.mainboard) {
        final mainboard = product as Mainboard;
        value = mainboard.ramSpec.toLocalizedString(S.of(context));
      }
      return _buildSpecificationRow(
          _getLocalizedSpecKey(context, entry.key), value);
    }).toList();
  }

  String _getLocalizedSpecKey(BuildContext context, String key) {
    switch (key.toLowerCase()) {
      case 'type':
        return S.of(context).driveType;
      case 'bus':
        return S.of(context).ramBus;
      case 'ram bus':
        return S.of(context).ramBus;
      case 'cl latency':
        return S.of(context).clLatency;
      case 'kit stick count':
        return S.of(context).kitStickCount;
      case 'capacity per stick':
        return S.of(context).capacityPerStick;
      case 'ram capacity':
        return S.of(context).ramCapacity;
      case 'ram type':
        return S.of(context).ramType;
      case 'cores':
        return S.of(context).cpuCore;
      case 'threads':
        return S.of(context).cpuThread;
      case 'base clock':
        return S.of(context).cpuClockSpeed;
      case 'turbo clock':
        return "Turbo Clock";
      case 'tdp':
        return "TDP";
      case 'socket':
        return S.of(context).compatibility;
      case 'series':
        return S.of(context).series;
      case 'version':
        return S.of(context).gpuVersion;
      case 'memory':
        return S.of(context).gpuMemory;
      case 'clock speed':
        return S.of(context).gpuClockSpeed;
      case 'i/o ports':
        return S.of(context).ioPorts;
      case 'chipset':
        return S.of(context).chipset;
      case 'form factor':
        return S.of(context).formFactor;
      case 'ram spec':
        return S.of(context).ramSpec;
      case 'storage:':
        return S.of(context).storageSlots;
      case 'pcie slots:':
        return S.of(context).pcieSlots;
      case 'drive type':
        return S.of(context).driveType;
      case 'generation':
        return S.of(context).driveGeneration;
      case 'interface':
        return S.of(context).driveInterface;
      case 'read speed':
        return S.of(context).readSpeed;
      case 'write speed':
        return S.of(context).writeSpeed;
      case 'capacity':
        return S.of(context).driveCapacity;
      case 'wattage':
        return S.of(context).psuWattage;
      case 'efficiency rating':
        return S.of(context).psuEfficiency;
      case 'modularity':
        return S.of(context).psuModular;
      case 'connectors':
        return S.of(context).connectors;
      default:
        return key;
    }
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 20,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildRatingAndCommentsSection() {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).ratingsAndReviews,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Rating Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  // Calculate star distribution
                  Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
                  for (var rating in state.ratings) {
                    if (rating.rating > 0 && rating.rating <= 5) {
                      starCounts[rating.rating] =
                          (starCounts[rating.rating] ?? 0) + 1;
                    }
                  }

                  final total = state.totalRatingsCount;
                  final avgRating = state.averageRating;
                  final hasRatings = total > 0;

                  if (isWide) {
                    return Row(
                      children: [
                        // Overall Rating
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                hasRatings
                                    ? avgRating.toStringAsFixed(1)
                                    : '0.0',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final starIndex = index + 1;
                                  final isFilled = hasRatings &&
                                      starIndex <= avgRating.round();
                                  return Icon(
                                    isFilled ? Icons.star : Icons.star_border,
                                    color: isFilled
                                        ? Colors.amber
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.3),
                                    size: 24,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasRatings
                                    ? S.of(context).reviews(total)
                                    : S.of(context).noRatingsYet,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 120,
                          color: Theme.of(context).dividerColor,
                        ),

                        // Rating Breakdown
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(5, (index) {
                                final starCount = 5 - index;
                                final count = starCounts[starCount] ?? 0;
                                final percentage =
                                    total > 0 ? (count / total * 100) : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$starCount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: percentage / 100,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 35,
                                        child: Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Column(
                          children: [
                            Text(
                              '0.0',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  Icons.star_border,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              S.of(context).noRatingsYet,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(
                          color: Theme.of(context).dividerColor,
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(5, (index) {
                            final starCount = 5 - index;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '$starCount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '0%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Comments List
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort/Filter bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).allReviews,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.sort,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'recent',
                            child: Text(S.of(context).mostRecent),
                          ),
                          PopupMenuItem(
                            value: 'helpful',
                            child: Text(S.of(context).mostHelpful),
                          ),
                          PopupMenuItem(
                            value: 'highest',
                            child: Text(S.of(context).highestRated),
                          ),
                          PopupMenuItem(
                            value: 'lowest',
                            child: Text(S.of(context).lowestRated),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Rating Cards or Empty State
                  if (state.ratings.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.reviews_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            S.of(context).noRatingsYet,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: state.ratings
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: RatingCard(rating: r),
                              ))
                          .toList(),
                    ),

                  // Show more button
                  if (state.hasMoreRatings)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await context
                                .read<ProductDetailCubit>()
                                .loadMoreRatings();
                          },
                          child: Text(S.of(context).showMore),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationsSection(
      BuildContext context, Product currentProduct) {
    final recs = RecommendationService()
        .getCompatibleForProduct(currentProduct)
        .where((p) => p.productID != currentProduct.productID)
        .toList();

    if (recs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).goodWithThisProduct,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 24,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1200;
          final crossAxisCount = isWide
              ? 5
              : constraints.maxWidth >= 900
                  ? 4
                  : 3;
          const double spacing = 16.0;

          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final product = recs[index];
              return GestureDetector(
                onTap: () async {
                  final productId = product.productID;
                  if (productId != null) {
                    await Navigator.of(context)
                        .pushNamed('/products/$productId');
                  }
                },
                child: WebProductCard(product: product),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildImageCarouselDesktop(
      BuildContext context, ProductDetailState state) {
    final hasImages = state.productImages.isNotEmpty;

    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 600,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: state.isLoadingImages
                ? const Center(child: CircularProgressIndicator())
                : hasImages
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.productImages.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            }
                          },
                          itemBuilder: (context, index) {
                            final image = state.productImages[index];
                            return Image.network(
                              image.url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getCategoryIcon(widget.product.category),
                                    size: 150,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.7)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getCategoryIcon(widget.product.category),
                          size: 150,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
        ),
        // Left navigation arrow
        if (hasImages &&
            state.productImages.length > 1 &&
            _currentImageIndex > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
        // Right navigation arrow
        if (hasImages &&
            state.productImages.length > 1 &&
            _currentImageIndex < state.productImages.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
        // Page indicator dots
        if (hasImages && state.productImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                state.productImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCarouselMobile(
      BuildContext context, ProductDetailState state) {
    final hasImages = state.productImages.isNotEmpty;

    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: state.isLoadingImages
                ? const Center(child: CircularProgressIndicator())
                : hasImages
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.productImages.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            }
                          },
                          itemBuilder: (context, index) {
                            final image = state.productImages[index];
                            return Image.network(
                              image.url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getCategoryIcon(widget.product.category),
                                    size: 120,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.7)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getCategoryIcon(widget.product.category),
                          size: 120,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
        ),
        // Page indicator dots
        if (hasImages && state.productImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                state.productImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        // Favorite button
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onPressed: () async {
              if (state.product.productID != null) {
                final isGuest = await _webGuestService.isCurrentUserGuest();
                if (isGuest) {
                  SnackbarService.showGuestRestriction(
                    context,
                    actionType: 'favorites',
                  );
                  return;
                }
                try {
                  final wasFavorite = state.isFavorite;
                  await cubit.toggleFavorite();
                  context.read<FavoritesCubit>().loadFavorites();
                  // Show snackbar notification
                  final newState = cubit.state;
                  if (newState.isFavorite != wasFavorite) {
                    SnackbarService.showFavoriteSuccess(
                      context,
                      newState.isFavorite ? 'added' : 'removed',
                    );
                  }
                } catch (e) {
                  SnackbarService.showFavoriteError(context);
                }
              }
            },
            child: Icon(
              state.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: state.isFavorite
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
