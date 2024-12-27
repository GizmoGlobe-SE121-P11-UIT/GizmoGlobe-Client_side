class Address {
  final String? addressID;
  final String receiverName;
  final String receiverPhone;
  final String? province;
  final String? district;
  final String? ward;
  final String? street;
  final bool isDefault;

  Address({
    this.addressID,
    required this.receiverName,
    required this.receiverPhone,
    this.province,
    this.district,
    this.ward,
    this.street,
    required this.isDefault,
  });

  @override
  String toString() {
    return '$receiverName - $receiverPhone' +
        (street != null ? ', $street' : '') +
        (ward != null ? ', $ward' : '') +
        (district != null ? ', $district' : '') +
        (province != null ? ', $province' : '');
  }
}