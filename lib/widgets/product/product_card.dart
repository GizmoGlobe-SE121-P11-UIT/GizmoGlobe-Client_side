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

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favorites) {
        final isFavorite =
            product.productID != null && favorites.contains(product.productID);

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
                          ProductDetailScreen.newInstance(product),
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
                                  product.productName,
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
                                      if (product.discount > 0) ...[
                                        Text(
                                          Helper.toCurrencyFormat(
                                              product.price),
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
                                            product.discountedPrice),
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
                                  product.discount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
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
                                            '-${product.discount.toStringAsFixed(0)}%',
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
                    if (product.productID != null) {
                      context.read<FavoritesCubit>().toggleFavorite(
                            product.productID!,
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

  IconData _getCategoryIcon() {
    switch (product.category) {
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
