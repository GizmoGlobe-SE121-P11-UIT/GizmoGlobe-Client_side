import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';

class AddAddressScreenState with EquatableMixin {
  final String receiverName;
  final String receiverPhone;
  final Province? province;
  final District? district;
  final Ward? ward;
  final String? street;

  const AddAddressScreenState({
    this.receiverName = '',
    this.receiverPhone = '',
    this.province,
    this.district,
    this.ward,
    this.street = '',
  });

  @override
  List<Object?> get props => [receiverName, receiverPhone, province, district, ward, street];

  AddAddressScreenState copyWith({
    String? receiverName,
    String? receiverPhone,
    Province? province,
    District? district,
    Ward? ward,
    String? street,
  }) {
    return AddAddressScreenState(
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      street: street ?? this.street,
    );
  }
}