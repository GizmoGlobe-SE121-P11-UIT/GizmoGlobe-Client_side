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

  // factory SalesInvoiceDetail.withQuantity({
  //   String? salesInvoiceDetailID,
  //   required String salesInvoiceID,
  //   required String productID,
  //   String? productName,
  //   String? category,
  //   required double sellingPrice,
  //   required int quantity,
  // }) {
  //   return SalesInvoiceDetail(
  //     salesInvoiceDetailID: salesInvoiceDetailID,
  //     salesInvoiceID: salesInvoiceID,
  //     productID: productID,
  //     productName: productName,
  //     category: category,
  //     sellingPrice: sellingPrice,
  //     quantity: quantity,
  //     subtotal: sellingPrice * quantity,
  //   );
  // }

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
      subtotal: subtotal ?? (quantity != null ? (sellingPrice ?? this.sellingPrice) * quantity : this.subtotal),
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
    return SalesInvoiceDetail(
      salesInvoiceDetailID: id,
      salesInvoiceID: map['salesInvoiceID'] ?? '',
      product: Database().productList.firstWhere((product) => product.productID == map['productID']),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
} 