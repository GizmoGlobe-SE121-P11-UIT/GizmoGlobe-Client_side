class WarrantyInvoiceDetail {
  String? warrantyInvoiceDetailID;
  String warrantyInvoiceID;
  String productID;
  int quantity;

  WarrantyInvoiceDetail({
    this.warrantyInvoiceDetailID,
    required this.warrantyInvoiceID,
    required this.productID,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'warrantyInvoiceID': warrantyInvoiceID,
      'productID': productID,
      'quantity': quantity,
    };
  }

  static WarrantyInvoiceDetail fromMap(String id, Map<String, dynamic> map) {
    return WarrantyInvoiceDetail(
      warrantyInvoiceDetailID: id,
      warrantyInvoiceID: map['warrantyInvoiceID'] ?? '',
      productID: map['productID'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }
} 