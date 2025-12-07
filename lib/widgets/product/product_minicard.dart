import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/main.dart' show rootNavigatorKey;
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_view.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_webview.dart';

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
    return InkWell(
      onTap: () => _openProductDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceVariant,
              ),
              child: Icon(
                _getCategoryIcon(),
                size: 36,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          Helper.toCurrencyFormat(_discountedPrice),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_sellingPrice != null &&
                          _sellingPrice! > _discountedPrice) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            Helper.toCurrencyFormat(_sellingPrice!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
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
