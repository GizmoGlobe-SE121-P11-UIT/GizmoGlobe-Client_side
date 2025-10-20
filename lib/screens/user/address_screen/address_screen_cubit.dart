import 'package:bloc/bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import 'address_screen_state.dart';

class AddressScreenCubit extends Cubit<AddressScreenState> {
  AddressScreenCubit() : super(const AddressScreenState());

  bool get _canEmit => !isClosed;
  void _safeEmit(AddressScreenState newState) {
    if (_canEmit) {
      emit(newState);
    }
  }

  Future<void> initialize() async {
    await reloadList();
  }

  Future<void> reloadList() async {
    // First fetch addresses from Firebase
    await Database().fetchAddress();
    // Then filter visible addresses
    final visibleAddresses =
        Database().addressList.where((address) => !address.hidden).toList();
    _safeEmit(state.copyWith(addressList: visibleAddresses));
  }

  Future<void> addAddress(Address address) async {
    await Firebase().createAddress(address);
    if (_canEmit) {
      await reloadList();
    }
  }

  Future<void> editAddress(Address address) async {
    await Firebase().updateAddress(address);
    if (_canEmit) {
      await reloadList();
    }
  }

  Future<void> deleteAddress(Address address) async {
    // Set address as hidden instead of deleting
    address.hidden = true;
    await Firebase().updateAddress(address);
    if (_canEmit) {
      await reloadList();
    }
  }
}
