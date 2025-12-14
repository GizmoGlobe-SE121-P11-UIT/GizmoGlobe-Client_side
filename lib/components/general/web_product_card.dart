import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_image.dart';
import 'package:gizmoglobe_client/widgets/product/favorites/favorites_cubit.dart';
import 'package:gizmoglobe_client/screens/cart/cart_screen/cart_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_view.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class WebProductCard extends StatefulWidget {
  final Product product;
  final bool showFavoriteIcon;
  final bool showCartButton;

  const WebProductCard({
    super.key,
    required this.product,
    this.showFavoriteIcon = true,
    this.showCartButton = true,
  });

  @override
  State<WebProductCard> createState() => _WebProductCardState();
}

class _WebProductCardState extends State<WebProductCard> {
  bool isHovered = false;
  bool _isAddHovered = false;
  final WebGuestService _webGuestService = WebGuestService();
  Future<ProductImage?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.product.productID != null) {
      _imageFuture =
          Firebase().getProductPrimaryImage(widget.product.productID!);
      _fetchAggregatedRating();
    }
  }

  Future<void> _fetchAggregatedRating() async {
    if (widget.product.productID == null) return;

    try {
      final aggregated = await Firebase()
          .getAggregatedProductRating(widget.product.productID!);

      if (aggregated != null && mounted) {
        final avgRating = (aggregated['avgRating'] as num?)?.toDouble() ?? 0.0;
        final ratingCount = (aggregated['ratingCount'] as num?)?.toInt() ?? 0;
        widget.product.setAggregatedRating(avgRating, ratingCount);
        if (mounted) setState(() {});
      }
    } catch (e) {
      // Silently fail - will show 0.0 rating
    }
  }

  @override
  void didUpdateWidget(WebProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh image future if product changed
    if (oldWidget.product.productID != widget.product.productID) {
      if (widget.product.productID != null) {
        _imageFuture =
            Firebase().getProductPrimaryImage(widget.product.productID!);
      } else {
        _imageFuture = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favorites) {
        final isFavorite = widget.product.productID != null &&
            favorites.contains(widget.product.productID);

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Material(
            elevation: isHovered ? 6 : 0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                final productId = widget.product.productID;
                if (kIsWeb && productId != null) {
                  // On web, use pushNamed for proper URL/history integration
                  await Navigator.of(context).pushNamed('/products/$productId');
                } else {
                  // On mobile, use traditional navigation
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen.newInstance(widget.product),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHovered
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)
                        : Theme.of(context).dividerColor,
                    width: isHovered ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: _imageFuture != null
                                    ? FutureBuilder<ProductImage?>(
                                        future: _imageFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.waiting ||
                                              !snapshot.hasData ||
                                              snapshot.data == null ||
                                              snapshot.data!.url.isEmpty) {
                                            return Center(
                                              child: Icon(
                                                _getCategoryIcon(
                                                    widget.product.category),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 96,
                                              ),
                                            );
                                          }
                                          return ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            child: CachedNetworkImage(
                                              key: ValueKey(
                                                  'product_image_${widget.product.productID}'),
                                              imageUrl: snapshot.data!.url,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              placeholder: (context, url) =>
                                                  Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.3),
                                                child: Center(
                                                  child: Icon(
                                                    _getCategoryIcon(widget
                                                        .product.category),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.3),
                                                    size: 48,
                                                  ),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Icon(
                                                  _getCategoryIcon(
                                                      widget.product.category),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  size: 96,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Icon(
                                          _getCategoryIcon(
                                              widget.product.category),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 96,
                                        ),
                                      ),
                              ),
                              // Discount badge
                              if (widget.product.discount > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-${widget.product.discount.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onError,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.showFavoriteIcon)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      if (widget.product.productID != null) {
                                        // Check if user is guest
                                        final isGuest = await _webGuestService
                                            .isCurrentUserGuest();
                                        if (isGuest) {
                                          SnackbarService.showGuestRestriction(
                                            context,
                                            actionType: 'favorites',
                                          );
                                          return;
                                        }

                                        try {
                                          final favoritesCubit =
                                              context.read<FavoritesCubit>();
                                          final wasFavorite =
                                              favoritesCubit.state.contains(
                                                  widget.product.productID!);
                                          await favoritesCubit.toggleFavorite(
                                            widget.product.productID!,
                                          );
                                          // Show success notification
                                          final isNowFavorite =
                                              favoritesCubit.state.contains(
                                                  widget.product.productID!);
                                          if (wasFavorite != isNowFavorite) {
                                            SnackbarService.showFavoriteSuccess(
                                              context,
                                              isNowFavorite
                                                  ? 'added'
                                                  : 'removed',
                                            );
                                          }
                                        } catch (e) {
                                          SnackbarService.showFavoriteError(
                                              context);
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Product Info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.productName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _buildRatingSection(context),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.product.discount > 0) ...[
                                      Text(
                                        Helper.toCurrencyFormat(
                                            widget.product.price),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      Helper.toCurrencyFormat(
                                          widget.product.discountedPrice),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.showCartButton)
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) =>
                                      setState(() => _isAddHovered = true),
                                  onExit: (_) =>
                                      setState(() => _isAddHovered = false),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      if (widget.product.productID != null) {
                                        // Check if user is guest
                                        final isGuest = await _webGuestService
                                            .isCurrentUserGuest();
                                        if (isGuest) {
                                          SnackbarService.showGuestRestriction(
                                            context,
                                            actionType: 'cart',
                                          );
                                          return;
                                        }

                                        _addToCart(context);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 100),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _isAddHovered
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.85)
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: _isAddHovered
                                            ? [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        size: 14,
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
            ),
          ),
        );
      },
    );
  }

  void _addToCart(BuildContext context) {
    try {
      // Add product to cart with quantity 1
      context.read<CartScreenCubit>().addToCart(
            widget.product.productID!,
            1,
          );

      // Show success feedback
      SnackbarService.showCartSuccess(context, widget.product.productName);
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => InformationDialog(
          dialogName: DialogName.failure,
          title: S.of(ctx).error,
          content: S.of(ctx).failedToAddToCart,
        ),
      );
    }
  }

  Widget _buildRatingSection(BuildContext context) {
    final double? rating = widget.product.rating;
    final int? ratingCount = widget.product.ratingCount;
    final String ratingText =
        (rating != null && rating > 0) ? rating.toStringAsFixed(1) : '0.0';
    final String countText = '(${ratingCount ?? 0})';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          ratingText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          countText,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return Icons.memory;
      case CategoryEnum.cpu:
        return Icons.computer;
      case CategoryEnum.psu:
        return Icons.power;
      case CategoryEnum.gpu:
        return Icons.videogame_asset;
      case CategoryEnum.drive:
        return Icons.storage;
      case CategoryEnum.mainboard:
        return Icons.developer_board;
      default:
        return Icons.device_unknown;
    }
  }
}
