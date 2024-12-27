import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';
import '../../../data/database/database.dart';
import '../../authentication/sign_in_screen/sign_in_view.dart';
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