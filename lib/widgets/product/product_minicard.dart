import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/main.dart' show rootNavigatorKey;
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_view.dart';

class ProductMiniCard extends StatelessWidget {
  final Map<String, dynamic> cardData;

  const ProductMiniCard({super.key, required this.cardData});

  String get _productId => cardData['id']?.toString() ?? '';

  String get _name => cardData['name']?.toString() ?? '';

  double get _discountedPrice =>
      (cardData['price'] is num) ? (cardData['price'] as num).toDouble() : 0;

  double? get _sellingPrice => (cardData['originalPrice'] is num)
      ? (cardData['originalPrice'] as num).toDouble()
      : null;

  String get _category => cardData['category']?.toString().toLowerCase() ?? '';

  Future<void> _openProductDetail(BuildContext context) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).unableToNavigate),
          ),
        );
      }
      return;
    }

    final product = _findProductById(_productId);

    if (product == null) {
      if (_productId.isNotEmpty) {
        navigator.pushNamed('/products/$_productId');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).productInfoLoading),
            ),
          );
        }
      }
      return;
    }

    final productId = product.productID;
    if (kIsWeb && productId != null) {
      await navigator.pushNamed('/products/$productId');
    } else {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen.newInstance(product),
        ),
      );
    }
  }

  IconData _getCategoryIcon() {
    switch (_category) {
      case 'ram':
        return Icons.memory;
      case 'cpu':
        return Icons.developer_board;
      case 'gpu':
        return Icons.videocam;
      case 'psu':
        return Icons.power;
      case 'drive':
        return Icons.storage;
      case 'mainboard':
        return Icons.dashboard;
      default:
        return Icons.devices;
    }
  }

  Product? _findProductById(String productId) {
    if (productId.isEmpty) return null;
    final db = Database();
    final List<Product> allProducts = [
      ...db.productList,
      ...db.cpuList,
      ...db.gpuList,
      ...db.mainboardList,
      ...db.ramList,
      ...db.psuList,
      ...db.driveList,
    ];

    try {
      return allProducts.firstWhere(
        (product) => product.productID == productId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 400;
    final isMobile = screenWidth < 600;
    
    // Responsive sizing - extra small for very narrow screens
    final iconSize = isVerySmall ? 40.0 : (isMobile ? 48.0 : 72.0);
    final iconRadius = isVerySmall ? 6.0 : (isMobile ? 8.0 : 12.0);
    final cardPadding = isVerySmall ? 8.0 : (isMobile ? 12.0 : 16.0);
    final spacing = isVerySmall ? 6.0 : (isMobile ? 8.0 : 12.0);
    final iconInnerSize = isVerySmall ? 20.0 : (isMobile ? 24.0 : 36.0);
    
    return InkWell(
      onTap: () => _openProductDetail(context),
      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(isVerySmall ? 8 : (isMobile ? 12 : 16)),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              blurRadius: isVerySmall ? 4 : (isMobile ? 8 : 12),
              offset: Offset(0, isVerySmall ? 2 : (isMobile ? 4 : 6)),
            ),
          ],
        ),
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconRadius),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                _getCategoryIcon(),
                size: iconInnerSize,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: (isVerySmall
                        ? theme.textTheme.bodyMedium
                        : (isMobile 
                            ? theme.textTheme.bodyLarge 
                            : theme.textTheme.titleMedium))?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isVerySmall ? 13 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isVerySmall ? 3 : (isMobile ? 4 : 8)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          Helper.toCurrencyFormat(_discountedPrice),
                          style: (isVerySmall
                              ? theme.textTheme.titleSmall
                              : (isMobile
                                  ? theme.textTheme.titleMedium
                                  : theme.textTheme.titleLarge))?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isVerySmall ? 14 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_sellingPrice != null &&
                          _sellingPrice! > _discountedPrice) ...[
                        SizedBox(width: isVerySmall ? 3 : (isMobile ? 4 : 8)),
                        Flexible(
                          child: Text(
                            Helper.toCurrencyFormat(_sellingPrice!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: isVerySmall ? 9 : (isMobile ? 10 : null),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
