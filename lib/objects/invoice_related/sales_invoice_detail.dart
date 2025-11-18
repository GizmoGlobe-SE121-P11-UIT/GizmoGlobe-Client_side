import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';

class SalesInvoiceDetail {
  final String? salesInvoiceDetailID;
  final String? salesInvoiceID;
  final Product product;
  final double sellingPrice;
  final int quantity;
  final double subtotal;

  SalesInvoiceDetail({
    this.salesInvoiceDetailID,
    this.salesInvoiceID,
    required this.product,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
  });

  SalesInvoiceDetail copyWith({
    String? salesInvoiceDetailID,
    String? salesInvoiceID,
    Product? product,
    double? sellingPrice,
    int? quantity,
    double? subtotal,
  }) {
    return SalesInvoiceDetail(
      salesInvoiceDetailID: salesInvoiceDetailID ?? this.salesInvoiceDetailID,
      salesInvoiceID: salesInvoiceID ?? this.salesInvoiceID,
      product: product ?? this.product,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ??
          (quantity != null
              ? (sellingPrice ?? this.sellingPrice) * quantity
              : this.subtotal),
    );
  }

  Map<String, dynamic> toMap(String salesInvoiceID) {
    return {
      'salesInvoiceDetailID': salesInvoiceDetailID,
      'salesInvoiceID': salesInvoiceID,
      'productID': product.productID,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  static SalesInvoiceDetail fromMap(String id, Map<String, dynamic> map) {
    final productID = map['productID'] as String?;
    if (productID == null || productID.isEmpty) {
      throw Exception('Product ID is missing in sales invoice detail');
    }

    // Try to find product in fullProductList first, then productList
    final product = Database().fullProductList.firstWhere(
      (product) => product.productID == productID,
      orElse: () {
        // Fallback to productList if not found in fullProductList
        return Database().productList.firstWhere(
              (product) => product.productID == productID,
              orElse: () => throw Exception(
                  'Product not found in any product list: $productID'),
            );
      },
    );

    return SalesInvoiceDetail(
      salesInvoiceDetailID: id,
      salesInvoiceID: map['salesInvoiceID'] ?? '',
      product: product,
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
}
