import 'package:bloc/bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import 'address_screen_state.dart';

class AddressScreenCubit extends Cubit<AddressScreenState> {
  AddressScreenCubit() : super(const AddressScreenState());

  Future<void> initialize() async {
    reloadList();
  }

  void reloadList() {
    final visibleAddresses = Database().addressList.where((address) => !address.hidden).toList();
    emit(state.copyWith(addressList: visibleAddresses));
  }

  Future<void> addAddress(Address address) async {
    await Firebase().createAddress(address);
    reloadList();
  }

  Future<void> editAddress(Address address) async {
    await Firebase().updateAddress(address);
    reloadList();
  }
}