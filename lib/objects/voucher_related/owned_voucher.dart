class OwnedVoucher {
  String? ownedVoucherID;
  String voucherID;
  String customerID;
  int numberOfUsage;

  OwnedVoucher({
    this.ownedVoucherID,
    required this.voucherID,
    required this.customerID,
    this.numberOfUsage = 0,
  });

  OwnedVoucher copyWith({
    String? ownedVoucherID,
    String? voucherID,
    String? customerID,
    int? numberOfUsage,
  }) {
    return OwnedVoucher(
      ownedVoucherID: ownedVoucherID ?? this.ownedVoucherID,
      voucherID: voucherID ?? this.voucherID,
      customerID: customerID ?? this.customerID,
      numberOfUsage: numberOfUsage ?? this.numberOfUsage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voucherID': voucherID,
      'customerID': customerID,
      'numberOfUsage': numberOfUsage,
    };
  }

  static OwnedVoucher fromMap(String id, Map<String, dynamic> map) {
    OwnedVoucher ownedVoucher = OwnedVoucher(
      ownedVoucherID: id,
      voucherID: map['voucherID'],
      customerID: map['customerID'],
      numberOfUsage: map['numberOfUsage'],
    );

    return ownedVoucher;
  }
} 