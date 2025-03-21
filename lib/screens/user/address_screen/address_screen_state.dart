import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/address_related/address.dart';

class AddressScreenState with EquatableMixin {
  final List<Address> addressList;

  const AddressScreenState({
    this.addressList = const [],
  });

  @override
  List<Object?> get props => [addressList];

  AddressScreenState copyWith({
    List<Address>? addressList,
  }) {
    return AddressScreenState(
      addressList: addressList ?? this.addressList,
    );
  }
}