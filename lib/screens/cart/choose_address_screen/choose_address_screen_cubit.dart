import 'package:bloc/bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import 'choose_address_screen_state.dart';

class ChooseAddressScreenCubit extends Cubit<ChooseAddressScreenState> {
  ChooseAddressScreenCubit() : super(const ChooseAddressScreenState());

  Future<void> initialize() async {
    await reloadList();
  }

  Future<void> reloadList() async {
    // First fetch addresses from Firebase
    await Database().fetchAddress();
    // Then filter visible addresses
    final visibleAddresses =
        Database().addressList.where((address) => !address.hidden).toList();
    emit(state.copyWith(addressList: visibleAddresses));
  }

  Future<void> addAddress(Address address) async {
    await Firebase().createAddress(address);
    await reloadList();
  }
}
