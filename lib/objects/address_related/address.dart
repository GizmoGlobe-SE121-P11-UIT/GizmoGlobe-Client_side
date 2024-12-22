class Address {
  final String? addressID;
  final String receiverName;
  final String receiverPhone;
  final String province;
  final String district;
  final String ward;
  final String street;
  final bool isDefault;

  Address({
    this.addressID,
    required this.receiverName,
    required this.receiverPhone,
    required this.province,
    required this.district,
    required this.ward,
    required this.street,
    required this.isDefault,
  });
}