import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_view.dart';
import '../../data/firebase/firebase.dart';
import '../../enums/product_related/category_enum.dart';
import '../../functions/helper.dart';
import '../../objects/product_related/product_image.dart';
import 'favorites/favorites_cubit.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  void initState() {
    super.initState();
    if (widget.product.productID != null) {
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
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favorites) {
        final isFavorite = widget.product.productID != null &&
            favorites.contains(widget.product.productID);

        return Card(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen.newInstance(widget.product),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: widget.product.productID != null
                            ? FutureBuilder<ProductImage?>(
                                future: Firebase().getProductPrimaryImage(
                                    widget.product.productID!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting ||
                                      !snapshot.hasData ||
                                      snapshot.data == null ||
                                      snapshot.data!.url.isEmpty) {
                                    return Container(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: Center(
                                        child: Icon(
                                          _getCategoryIcon(),
                                          size: 36,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: snapshot.data!.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: Center(
                                        child: Icon(
                                          _getCategoryIcon(),
                                          size: 36,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: Center(
                                        child: Icon(
                                          _getCategoryIcon(),
                                          size: 36,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(),
                                    size: 36,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.product.productName,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      if (widget.product.discount > 0) ...[
                                        Text(
                                          Helper.toCurrencyFormat(
                                              widget.product.price),
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withValues(alpha: 0.9),
                                            decorationThickness: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withValues(alpha: 0.9),
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        Helper.toCurrencyFormat(
                                            widget.product.discountedPrice),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      _buildRatingSection(),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      widget.product.discount > 0
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red[400] : Colors.grey,
                  ),
                  onPressed: () {
                    if (widget.product.productID != null) {
                      context.read<FavoritesCubit>().toggleFavorite(
                            widget.product.productID!,
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSection() {
    final double? rating = widget.product.rating;
    final int? ratingCount = widget.product.ratingCount;
    final String ratingText =
        (rating != null && rating > 0) ? rating.toStringAsFixed(1) : '0.0';
    final String countText = '(${ratingCount ?? 0})';

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
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
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            countText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w400,
              fontSize: 11,
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
      case CategoryEnum.empty:
        return Icons.devices;
    }
  }
}
