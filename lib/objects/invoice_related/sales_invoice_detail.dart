class SalesInvoiceDetail {
  final String? salesInvoiceDetailID;
  final String salesInvoiceID;
  final String productID;
  final String? productName;
  final String? category;
  final double sellingPrice;
  final int quantity;
  final double subtotal;

  SalesInvoiceDetail({
    this.salesInvoiceDetailID,
    required this.salesInvoiceID,
    required this.productID,
    this.productName,
    this.category,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory SalesInvoiceDetail.withQuantity({
    String? salesInvoiceDetailID,
    required String salesInvoiceID,
    required String productID,
    String? productName,
    String? category,
    required double sellingPrice,
    required int quantity,
  }) {
    return SalesInvoiceDetail(
      salesInvoiceDetailID: salesInvoiceDetailID,
      salesInvoiceID: salesInvoiceID,
      productID: productID,
      productName: productName,
      category: category,
      sellingPrice: sellingPrice,
      quantity: quantity,
      subtotal: sellingPrice * quantity,
    );
  }

  SalesInvoiceDetail copyWith({
    String? salesInvoiceDetailID,
    String? salesInvoiceID,
    String? productID,
    String? productName,
    String? category,
    double? sellingPrice,
    int? quantity,
    double? subtotal,
  }) {
    return SalesInvoiceDetail(
      salesInvoiceDetailID: salesInvoiceDetailID ?? this.salesInvoiceDetailID,
      salesInvoiceID: salesInvoiceID ?? this.salesInvoiceID,
      productID: productID ?? this.productID,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? (quantity != null ? (sellingPrice ?? this.sellingPrice) * quantity : this.subtotal),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesInvoiceDetailID': salesInvoiceDetailID,
      'salesInvoiceID': salesInvoiceID,
      'productID': productID,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  static SalesInvoiceDetail fromMap(String id, Map<String, dynamic> map) {
    return SalesInvoiceDetail(
      salesInvoiceDetailID: id,
      salesInvoiceID: map['salesInvoiceID'] ?? '',
      productID: map['productID'] ?? '',
      productName: map['productName'],
      category: map['category'],
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
} 