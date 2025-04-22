import 'package:bloc/bloc.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';
import '../../../objects/address_related/address.dart';
import 'edit_address_screen_state.dart';

class EditAddressScreenCubit extends Cubit<AddAddressScreenState> {
  EditAddressScreenCubit() : super(const AddAddressScreenState());

  void initialize(Address address) {
    emit(state.copyWith(
      addressID: address.addressID,
      customerID: address.customerID,
      receiverName: address.receiverName,
      receiverPhone: address.receiverPhone,
      province: address.province,
      district: address.district,
      ward: address.ward,
      street: address.street,
      hidden: address.hidden,
    ));
  }

  void updateAddress({
    String? receiverName,
    String? receiverPhone,
    Province? province,
    District? district,
    Ward? ward,
    String? street,
    bool? hidden,
  }) {
    emit(state.copyWith(
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      province: province,
      district: district,
      ward: ward,
      street: street,
      hidden: hidden,
    ));
  }

  Address getAddresses() {
    return Address(
      addressID: state.addressID,
      customerID: state.customerID,
      receiverName: state.receiverName,
      receiverPhone: state.receiverPhone,
      province: state.province,
      district: state.district,
      ward: state.ward,
      street: state.street,
      hidden: state.hidden,
    );
  }
}