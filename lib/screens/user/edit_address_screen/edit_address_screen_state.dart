import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';

class AddAddressScreenState with EquatableMixin {
  final String addressID;
  final String customerID;
  final String receiverName;
  final String receiverPhone;
  final Province? province;
  final District? district;
  final Ward? ward;
  final String? street;
  final bool hidden;

  const AddAddressScreenState({
    this.addressID = '',
    this.customerID = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.province,
    this.district,
    this.ward,
    this.street = '',
    this.hidden = false,
  });

  @override
  List<Object?> get props => [customerID, receiverName, receiverPhone, province, district, ward, street, hidden, addressID];

  AddAddressScreenState copyWith({
    String? customerID,
    String? addressID,
    String? receiverName,
    String? receiverPhone,
    Province? province,
    District? district,
    Ward? ward,
    String? street,
    bool? hidden,
  }) {
    return AddAddressScreenState(
      addressID: addressID ?? this.addressID,
      customerID: customerID ?? this.customerID,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      street: street ?? this.street,
      hidden: hidden ?? this.hidden,
    );
  }
}