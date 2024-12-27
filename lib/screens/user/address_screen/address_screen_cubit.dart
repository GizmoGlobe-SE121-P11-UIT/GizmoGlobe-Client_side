import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import '../../authentication/sign_in_screen/sign_in_view.dart';
import 'address_screen_state.dart';


class AddressScreenCubit extends Cubit<AddressScreenState> {
  AddressScreenCubit() : super(const AddressScreenState());

  Future<void> initialize() async {
    reloadList();
  }

  void reloadList() {
    emit(state.copyWith(addressList: Database().addressList));
  }

  Future<void> addAddress(Address address) async {
    await Firebase().createAddress(address);
    reloadList();
  }
}