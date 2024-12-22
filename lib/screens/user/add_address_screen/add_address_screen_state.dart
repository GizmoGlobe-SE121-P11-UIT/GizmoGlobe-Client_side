import 'package:equatable/equatable.dart';

class AddAddressScreenState with EquatableMixin {
  final String receiverName;
  final String receiverPhone;
  final String province;
  final String district;
  final String ward;
  final String street;
  final bool isDefault;

  const AddAddressScreenState({
    this.receiverName = '',
    this.receiverPhone = '',
    this.province = '',
    this.district = '',
    this.ward = '',
    this.street = '',
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [receiverName, receiverPhone, province, district, ward, street, isDefault];

  AddAddressScreenState copyWith({
    String? receiverName,
    String? receiverPhone,
    String? province,
    String? district,
    String? ward,
    String? street,
    bool? isDefault,
  }) {
    return AddAddressScreenState(
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      street: street ?? this.street,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}