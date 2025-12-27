import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_view.dart';

class WebFavoritesSection extends StatelessWidget {
  final List<Product> products;

  const WebFavoritesSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).yourFavorites,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).productsInYourWishlist,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  if (kIsWeb) {
                    // Use PageRouteBuilder without RouteSettings to avoid browser history conflicts
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ProductScreen.newInstance(
                          initialProducts: products,
                          isFavorites: true,
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 150),
                        opaque: false,
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductScreen.newInstance(
                          initialProducts: products,
                          isFavorites: true,
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      S.of(context).seeAll,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  margin: EdgeInsets.only(
                    right: index < products.length - 1 ? 20 : 0,
                  ),
                  child: WebProductCard(product: products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
