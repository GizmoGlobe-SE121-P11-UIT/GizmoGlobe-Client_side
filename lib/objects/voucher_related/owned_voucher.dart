class OwnedVoucher {
  String? ownedVoucherID;
  String voucherID;
  String customerID;
  int numberOfUses;

  OwnedVoucher({
    this.ownedVoucherID,
    required this.voucherID,
    required this.customerID,
    this.numberOfUses = 0,
  });

  OwnedVoucher copyWith({
    String? ownedVoucherID,
    String? voucherID,
    String? customerID,
    int? numberOfUses,
  }) {
    return OwnedVoucher(
      ownedVoucherID: ownedVoucherID ?? this.ownedVoucherID,
      voucherID: voucherID ?? this.voucherID,
      customerID: customerID ?? this.customerID,
      numberOfUses: numberOfUses ?? this.numberOfUses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voucherID': voucherID,
      'customerID': customerID,
      'numberOfUses': numberOfUses,
    };
  }

  static OwnedVoucher fromMap(String id, Map<String, dynamic> map) {
    OwnedVoucher ownedVoucher = OwnedVoucher(
      ownedVoucherID: id,
      voucherID: map['voucherID'],
      customerID: map['customerID'],
      numberOfUses: map['numberOfUses'],
    );

    return ownedVoucher;
  }
} 