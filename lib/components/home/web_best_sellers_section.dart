import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_view.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';

class WebBestSellersSection extends StatelessWidget {
  final List<Product> products;

  const WebBestSellersSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth >= 900
            ? 80
            : screenWidth >= 600
                ? 40
                : 20,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: show more cards on wider screens
          final maxCards = constraints.maxWidth >= 1400
              ? 7
              : constraints.maxWidth >= 1200
                  ? 6
                  : constraints.maxWidth >= 900
                      ? 5
                      : constraints.maxWidth >= 600
                          ? 3
                          : 2; // Added mobile breakpoint
          final displayCount =
              products.length > maxCards ? maxCards : products.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).bestSellers,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isMobile ? 24 : 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isMobile ? -0.5 : -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.of(context).topRatedProductsLovedByCustomers,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: isMobile ? 14 : 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductScreen.newInstance(
                            initialSortOption: SortEnum.salesHighest,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          S.of(context).seeAll,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
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
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(
                        right: index < displayCount - 1 ? 20 : 0,
                      ),
                      child: WebProductCard(product: products[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
