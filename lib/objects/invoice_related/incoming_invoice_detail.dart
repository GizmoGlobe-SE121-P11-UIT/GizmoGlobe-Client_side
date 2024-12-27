class IncomingInvoiceDetail {
  String? incomingInvoiceDetailID;
  String incomingInvoiceID;
  String productID;
  double importPrice;
  int quantity;
  double subtotal;

  IncomingInvoiceDetail({
    this.incomingInvoiceDetailID,
    required this.incomingInvoiceID,
    required this.productID,
    required this.importPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'incomingInvoiceID': incomingInvoiceID,
      'productID': productID,
      'importPrice': importPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  static IncomingInvoiceDetail fromMap(String id, Map<String, dynamic> map) {
    return IncomingInvoiceDetail(
      incomingInvoiceDetailID: id,
      incomingInvoiceID: map['incomingInvoiceID'] ?? '',
      productID: map['productID'] ?? '',
      importPrice: (map['importPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
} 