import 'package:bloc/bloc.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';
import 'add_address_screen_state.dart';

class AddAddressScreenCubit extends Cubit<AddAddressScreenState> {
  AddAddressScreenCubit() : super(const AddAddressScreenState());

  void updateAddress({
    String? receiverName,
    String? receiverPhone,
    Province? province,
    District? district,
    Ward? ward,
    String? street,
    bool? isDefault,
  }) {
    emit(state.copyWith(
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      province: province,
      district: district,
      ward: ward,
      street: street,
    ));
  }
}