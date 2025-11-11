import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/services/recommendation_service.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/widgets/product/favorites/favorites_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';

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

  String? _previousHashPath;

  @override
  void initState() {
    super.initState();
    // Append the product ID to the current URL hash so deep links reflect the product
    final productId = widget.product.productID;
    if (productId != null && productId.isNotEmpty) {
      _previousHashPath = platform_actions.getHashPath();
      final current = _previousHashPath ?? '';
      final normalized = current.endsWith('/$productId')
          ? current
          : (current.endsWith('/')
              ? '$current$productId'
              : '$current/$productId');
      // Replace the hash without pushing history to avoid route changes
      platform_actions.replaceHashUrl(normalized);
    }
  }

  @override
  void dispose() {
    // Restore previous hash (remove the productId suffix) when leaving detail page
    final productId = widget.product.productID;
    if (productId != null && productId.isNotEmpty) {
      final current = platform_actions.getHashPath();
      if (current.endsWith('/$productId')) {
        final restored =
            current.substring(0, current.length - productId.length - 1);
        // Avoid empty hash – default to '/products' if needed
        platform_actions
            .replaceHashUrl(restored.isEmpty ? '/products' : restored);
      }
    }
    super.dispose();
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
          if (state.message.toLowerCase().contains('added') &&
              state.message.toLowerCase().contains('cart')) {
            // Extract product name from message or use widget.product.productName
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
          // Check if it's a cart failure
          if (state.message.toLowerCase().contains('cart')) {
            SnackbarService.showCartError(context);
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
                              Navigator.pushNamed(context, '/products');
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
                              Navigator.pop(context);
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
                                                  Card(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Container(
                                                      height: 600,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .surface
                                                                .withValues(
                                                                    alpha: 0.1)
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHighest,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        image: state.product
                                                                        .imageUrl !=
                                                                    null &&
                                                                state
                                                                    .product
                                                                    .imageUrl!
                                                                    .isNotEmpty
                                                            ? DecorationImage(
                                                                image: NetworkImage(
                                                                    state
                                                                        .product
                                                                        .imageUrl!),
                                                                fit: BoxFit
                                                                    .contain,
                                                              )
                                                            : null,
                                                      ),
                                                      child: state.product
                                                                      .imageUrl ==
                                                                  null ||
                                                              state
                                                                  .product
                                                                  .imageUrl!
                                                                  .isEmpty
                                                          ? Center(
                                                              child: Icon(
                                                                _getCategoryIcon(
                                                                    widget
                                                                        .product
                                                                        .category),
                                                                size: 150,
                                                                color: Theme.of(context)
                                                                            .brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withValues(
                                                                            alpha:
                                                                                0.7)
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                  ),
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
                                                            const Spacer(),
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
                                                            SizedBox(
                                                              width: 300,
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
                                                                    Icon(
                                                                      Icons
                                                                          .shopping_cart_outlined,
                                                                      size: 20,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Text(
                                                                      S
                                                                          .of(context)
                                                                          .addToCart,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        letterSpacing:
                                                                            0.5,
                                                                      ),
                                                                    ),
                                                                  ],
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
                                            Stack(
                                              children: [
                                                Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Container(
                                                    height: 400,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .surface
                                                              .withValues(
                                                                  alpha: 0.1)
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      image: state.product
                                                                      .imageUrl !=
                                                                  null &&
                                                              state
                                                                  .product
                                                                  .imageUrl!
                                                                  .isNotEmpty
                                                          ? DecorationImage(
                                                              image: NetworkImage(
                                                                  state.product
                                                                      .imageUrl!),
                                                              fit: BoxFit
                                                                  .contain,
                                                            )
                                                          : null,
                                                    ),
                                                    child: state.product
                                                                    .imageUrl ==
                                                                null ||
                                                            state
                                                                .product
                                                                .imageUrl!
                                                                .isEmpty
                                                        ? Center(
                                                            child: Icon(
                                                              _getCategoryIcon(
                                                                  widget.product
                                                                      .category),
                                                              size: 120,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .dark
                                                                  ? Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary
                                                                      .withValues(
                                                                          alpha:
                                                                              0.7)
                                                                  : Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurfaceVariant,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 16,
                                                  top: 16,
                                                  child: FloatingActionButton(
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
                                                              state.isFavorite;
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
                                                      color: state.isFavorite
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .error
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                                          Icon(
                                                            Icons
                                                                .shopping_cart_outlined,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            S
                                                                .of(context)
                                                                .addToCart,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                          ),
                                                        ],
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
    return specs.entries
        .map((entry) => _buildSpecificationRow(
            _getLocalizedSpecKey(context, entry.key), entry.value))
        .toList();
  }

  String _getLocalizedSpecKey(BuildContext context, String key) {
    switch (key.toLowerCase()) {
      case 'type':
        return S.of(context).driveType;
      case 'capacity':
        return "Drive Capacity";
      case 'bus':
        return "RAM Bus";
      case 'cl latency':
        return "CL Latency";
      case 'kit stick count':
        return "Kit Stick Count";
      case 'capacity per stick':
        return "RAM Capacity";
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
      case 'version':
        return "GPU Version";
      case 'memory':
        return "GPU Memory";
      case 'clock speed':
        return S.of(context).gpuClockSpeed;
      case 'i/o ports':
        return "I/O Ports";
      case 'chipset':
        return S.of(context).series;
      case 'form factor':
        return S.of(context).formFactor;
      case 'ram spec':
        return "RAM Spec";
      case 'storage:':
        return "Storage Slots";
      case 'pcie slots:':
        return "PCIe Slots";
      case 'drive type':
        return S.of(context).driveType;
      case 'generation':
        return "Generation";
      case 'interface':
        return "Interface";
      case 'read speed':
        return "Read Speed";
      case 'write speed':
        return "Write Speed";
      case 'wattage':
        return S.of(context).psuWattage;
      case 'efficiency rating':
        return "PSU Efficiency";
      case 'modularity':
        return "Modularity";
      case 'connectors':
        return "Connectors";
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
            width: 140,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Ratings & Reviews',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 24,
                color: Theme.of(context).colorScheme.primary,
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
              if (isWide) {
                return Row(
                  children: [
                    // Overall Rating
                    Expanded(
                      child: Column(
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
                            'No ratings yet',
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
                      height: 80,
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
                          'No ratings yet',
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
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
                                        borderRadius: BorderRadius.circular(4),
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
                    'All Reviews',
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
                        child: Text('Most Recent'),
                      ),
                      PopupMenuItem(
                        value: 'helpful',
                        child: Text('Most Helpful'),
                      ),
                      PopupMenuItem(
                        value: 'highest',
                        child: Text('Highest Rated'),
                      ),
                      PopupMenuItem(
                        value: 'lowest',
                        child: Text('Lowest Rated'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Empty State
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
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share your experience!',
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
            ],
          ),
        ),
      ],
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
          'Good with this product',
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
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) =>
                          ProductDetailScreenWebView.newInstance(product),
                    ),
                  );
                },
                child: WebProductCard(product: product),
              );
            },
          );
        }),
      ],
    );
  }
}
