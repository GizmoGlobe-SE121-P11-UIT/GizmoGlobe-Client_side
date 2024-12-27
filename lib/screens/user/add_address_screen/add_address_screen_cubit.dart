import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/database/database.dart';
import '../../authentication/sign_in_screen/sign_in_view.dart';
import 'add_address_screen_state.dart';


class AddAddressScreenCubit extends Cubit<AddAddressScreenState> {
  AddAddressScreenCubit() : super(const AddAddressScreenState());

  void updateAddress({
    String? receiverName,
    String? receiverPhone,
    String? province,
    String? district,
    String? ward,
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
      isDefault: isDefault,
    ));
  }
}